package com.slinkydeveloper.eventing.hyperfoil.benchmark;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

import io.hyperfoil.Hyperfoil;
import io.hyperfoil.api.statistics.Statistics;
import io.hyperfoil.clustering.BaseAuxiliaryVerticle;
import io.hyperfoil.clustering.Feeds;
import io.hyperfoil.clustering.messages.RequestStatsMessage;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.Promise;
import io.vertx.core.http.HttpServerRequest;

public class VertxReceiverVerticle extends BaseAuxiliaryVerticle {

  private final static String CE_BENCHMARK_TIMESTAMP_EXTENSION = "ce-benchmarktimestamp";
  private final static String CE_PHASE = "ce-phase";
  private final static String CE_RUNID = "ce-runId";
  private final static String CE_METRIC = "ce-metric";

  private String runId;
  private String phaseId;
  private String metric;
  private Statistics stats;
  private boolean recorded = false;

  @Override
  public void start(Promise<Void> startPromise) {
    start();
    vertx.setPeriodic(1000, v -> sendStats());
    vertx.createHttpServer()
        .requestHandler(this::handleRequest)
        .listen(8080)
        .<Void>mapEmpty()
        .onComplete(startPromise);
    vertx.setPeriodic(60000, id -> {
      // If we do not receive anything for more than 1 minute we'll let statistics be garbage-collected.
      // TODO: compacting stats would be a better approach
      if (recorded) {
        recorded = false;
      } else if (stats != null){
        stats = null;
      }
    });
  }

  private void handleRequest(HttpServerRequest request) {
    long now = System.currentTimeMillis();
    long sendTimestamp = Long.parseLong(request.getHeader(CE_BENCHMARK_TIMESTAMP_EXTENSION));

    String runId = request.getHeader(CE_RUNID);
    String phaseId = request.getHeader(CE_PHASE);
    String metric = request.getHeader(CE_METRIC);
    if (stats == null || !Objects.equals(runId, this.runId) || !Objects.equals(phaseId, this.phaseId)|| !Objects.equals(metric, this.metric)) {
      log.info("Starting data for run {}, phase {}, metric {}, first timestamp is {}", runId, phaseId, metric, new SimpleDateFormat("yyyy-MM-dd hh:mm:ss.S").format(new Date(sendTimestamp)));
      this.runId = runId;
      this.phaseId = phaseId;
      this.metric = metric;
      stats = new Statistics(now);
      // Hyperfoil does not publish the last bucket until the stats are marked as complete.
      // We don't have to care about that since here we're running single-threaded and never know when
      // we are actually complete.
      stats.end(now);
    }

    stats.incrementRequests(sendTimestamp);
    stats.recordResponse(sendTimestamp, 0, TimeUnit.MILLISECONDS.toNanos(now - sendTimestamp));
    request.response().setStatusCode(202).end();
  }

  private void sendStats() {
    if (stats == null || phaseId == null || runId == null || metric == null) {
      return;
    }
    int phaseId = Integer.parseInt(this.phaseId);
    stats.visitSnapshots(snapshot -> {
      if (snapshot.requestCount > 0) {
        log.info("Sending stats #{} ({} requests) to controller", snapshot.sequenceId, snapshot.requestCount);
        vertx.eventBus().send(Feeds.STATS, new RequestStatsMessage(deploymentID(), runId, phaseId, false, 0, metric, snapshot));
      }
    });
  }

  public static void main(String[] args) {
    Hyperfoil.clusteredVertx(false)
          .onSuccess(vertx -> vertx.deployVerticle(VertxReceiverVerticle.class, new DeploymentOptions()));
  }
}
