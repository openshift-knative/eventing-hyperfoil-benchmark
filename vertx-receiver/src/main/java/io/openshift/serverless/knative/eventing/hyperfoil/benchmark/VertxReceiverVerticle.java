package io.openshift.serverless.knative.eventing.hyperfoil.benchmark;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

import io.hyperfoil.Hyperfoil;
import io.hyperfoil.api.statistics.Statistics;
import io.hyperfoil.api.statistics.StatisticsSnapshot;
import io.hyperfoil.clustering.BaseAuxiliaryVerticle;
import io.hyperfoil.clustering.Feeds;
import io.hyperfoil.clustering.messages.DelayStatsCompletionMessage;
import io.hyperfoil.clustering.messages.RequestStatsMessage;
import io.vertx.core.DeploymentOptions;
import io.vertx.core.Promise;
import io.vertx.core.http.HttpServerRequest;

public class VertxReceiverVerticle extends BaseAuxiliaryVerticle {
  private final static long GARBAGE_COLLECTION_PERIOD = Long.getLong("receiver.gc.period", 60000);
  private final static long COMPLETION_DELAY_REQUEST_PERIOD = Long.getLong("receiver.gc.period", 5000);

  private final static String CE_BENCHMARK_TIMESTAMP_EXTENSION = "ce-benchmarktimestamp";
  private final static String CE_PHASE_START_TIMESTAMP = "ce-phasestart";
  private final static String CE_PHASE = "ce-phase";
  private final static String CE_RUNID = "ce-runId";
  private final static String CE_METRIC = "ce-metric";

  private final List<PhaseStats> phaseStats = new ArrayList<>();

  @Override
  public void start(Promise<Void> startPromise) {
    start();
    vertx.setPeriodic(1000, v -> sendStats());
    vertx.createHttpServer()
        .requestHandler(this::handleRequest)
        .listen(8080)
        .<Void>mapEmpty()
        .onComplete(startPromise);
    vertx.setPeriodic(GARBAGE_COLLECTION_PERIOD, id -> {
      // If we do not receive anything for more than 1 minute we'll let statistics be garbage-collected.
      // TODO: compacting stats would be a better approach
      for (Iterator<PhaseStats> iterator = phaseStats.iterator(); iterator.hasNext(); ) {
        PhaseStats ps = iterator.next();
        if (ps.recordedForGc) {
          ps.recordedForGc = false;
        } else {
          iterator.remove();
        }
      }
    });
    vertx.setPeriodic(COMPLETION_DELAY_REQUEST_PERIOD, id -> {
      for (PhaseStats ps : phaseStats) {
        if (ps.recordedForDelay) {
          ps.recordedForDelay = false;
          int phaseId = Integer.parseInt(ps.phaseId);
          vertx.eventBus().send(Feeds.STATS, new DelayStatsCompletionMessage(deploymentID(), ps.runId, phaseId, 2 * COMPLETION_DELAY_REQUEST_PERIOD));
        }
      }
    });
  }

  private void handleRequest(HttpServerRequest request) {
    long now = System.currentTimeMillis();
    long sendTimestamp = Long.parseLong(request.getHeader(CE_BENCHMARK_TIMESTAMP_EXTENSION));

    String runId = request.getHeader(CE_RUNID);
    String phaseId = request.getHeader(CE_PHASE);
    String metric = request.getHeader(CE_METRIC);
    PhaseStats found = null;
    for (PhaseStats ps : phaseStats) {
      if (Objects.equals(runId, ps.runId) && Objects.equals(phaseId, ps.phaseId) && Objects.equals(metric, ps.metric)) {
        found = ps;
        break;
      }
    }
    if (found == null) {
      String startTimestampStr = request.getHeader(CE_PHASE_START_TIMESTAMP);
      long startTimestamp = startTimestampStr == null ? sendTimestamp : Long.parseLong(startTimestampStr);
      log.info("Starting data for run {}, phase {}, metric {}, first timestamp is {}", runId, phaseId, metric, new SimpleDateFormat("yyyy-MM-dd hh:mm:ss.S").format(new Date(sendTimestamp)));
      found = new PhaseStats(runId, phaseId, metric, startTimestamp);
      phaseStats.add(0, found);
    }
    found.recordedForGc = true;
    found.recordedForDelay = true;
    found.stats.incrementRequests(sendTimestamp);
    found.stats.recordResponse(sendTimestamp,  TimeUnit.MILLISECONDS.toNanos(Math.max(0, now - sendTimestamp)));
    request.response().setStatusCode(202).end();
  }

  private void sendStats() {
    for (PhaseStats ps : phaseStats) {
      int phaseId = Integer.parseInt(ps.phaseId);
      ps.stats.visitSnapshots(snapshot -> {
        if (snapshot.requestCount > 0) {
          // We need to copy the snapshot because sending on event-bus is asynchronous
          StatisticsSnapshot clone = snapshot.clone();
          // Normally end time is capped to Statistics.endTime (which we have set prematurely)
          clone.histogram.setEndTimeStamp(clone.histogram.getStartTimeStamp() + 1000);
          log.info("Sending stats {}/{}/{} #{} ({} requests) to controller", ps.runId, ps.phaseId, ps.metric, clone.sequenceId, clone.requestCount);
          vertx.eventBus().send(Feeds.STATS, new RequestStatsMessage(deploymentID(), ps.runId, phaseId, false, 0, ps.metric, clone));
        }
      });
    }
  }

  public static void main(String[] args) {
    Hyperfoil.clusteredVertx(false)
          .onSuccess(vertx -> vertx.deployVerticle(VertxReceiverVerticle.class, new DeploymentOptions()));
  }

  public static class PhaseStats {
    private final String runId;
    private final String phaseId;
    private final String metric;
    private final Statistics stats;
    private boolean recordedForGc = false;
    private boolean recordedForDelay = false;

    public PhaseStats(String runId, String phaseId, String metric, long startTimestamp) {
      this.runId = runId;
      this.phaseId = phaseId;
      this.metric = metric;
      this.stats = new Statistics(startTimestamp);
      // Hyperfoil does not publish the last bucket until the stats are marked as complete.
      // We don't have to care about that since here we're running single-threaded and never know when
      // we are actually complete.
      stats.end(startTimestamp);
    }
  }
}
