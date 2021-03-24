package com.slinkydeveloper.eventing.hyperfoil.benchmark;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Promise;
import io.vertx.core.http.HttpServerRequest;
import org.HdrHistogram.Histogram;

public class VertxReceiverVerticle extends AbstractVerticle {

  private final Histogram histogram;

  public VertxReceiverVerticle() {
    this.histogram = new Histogram(1);
  }

  @Override
  public void start(Promise<Void> startPromise) throws Exception {
    vertx.createHttpServer()
        .requestHandler(this::handleRequest)
        .listen(8080)
        .<Void>mapEmpty()
        .onComplete(startPromise);
  }

  private void handleRequest(HttpServerRequest httpServerRequest) {
    // TODO

    // Check the type:
    //   if type == data point -> record to the histogram
    //   if type == stop -> print histogram and close
  }
}
