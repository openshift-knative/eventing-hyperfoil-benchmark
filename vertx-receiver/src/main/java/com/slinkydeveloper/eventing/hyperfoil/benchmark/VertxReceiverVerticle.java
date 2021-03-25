package com.slinkydeveloper.eventing.hyperfoil.benchmark;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
import io.vertx.core.Vertx;
import io.vertx.core.http.HttpServerRequest;
import org.HdrHistogram.Histogram;

public class VertxReceiverVerticle extends AbstractVerticle {

  private final static String CE_TYPE = "ce-type";
  private final static String CE_BENCHMARK_TIMESTAMP_EXTENSION = "ce-benchmarktimestamp";
  private final static String DATA_POINT_TYPE = "datapoint.hyperfoilbench";
  private final static String STOP_TYPE = "stop.hyperfoilbench";

  private final Histogram histogram;

  public VertxReceiverVerticle() {
    this.histogram = new Histogram(1);
  }

  @Override
  public void start(Promise<Void> startPromise) {
    vertx.setPeriodic(1000, v -> printStats());
    vertx.createHttpServer()
        .requestHandler(this::handleRequest)
        .listen(8080)
        .<Void>mapEmpty()
        .onComplete(startPromise);
  }

  private void handleRequest(HttpServerRequest httpServerRequest) {
    String type = httpServerRequest.getHeader(CE_TYPE);

    // Check the type:
    //   if type == data point -> record to the histogram
    //   if type == stop -> print histogram and close

    if (STOP_TYPE.equals(type)) {
      System.out.println("Received stop signal");
      printStats();
      vertx.undeploy(this.deploymentID());
    } else {
      // Maybe we need a warmup phase too where we "skip" the data? Or is this handled by hyperfoil?
      long now = System.currentTimeMillis();

      this.histogram.recordValue(
          now - Long.parseLong(httpServerRequest.getHeader(CE_BENCHMARK_TIMESTAMP_EXTENSION))
      );
    }
    httpServerRequest.response().setStatusCode(202).end();
  }

  private void printStats() {
    System.out.printf(
        "Now: %d, Mean: %f, std-deviation: %f\n",
        System.currentTimeMillis(),
        this.histogram.getMean(),
        this.histogram.getStdDeviation()
    );
  }

  public static void main(String[] args) {
    Vertx vertx = Vertx.vertx();
    vertx.deployVerticle(new VertxReceiverVerticle());
  }

}
