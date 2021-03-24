package com.slinkydeveloper.hyperfoil.extensions;

import java.util.List;
import java.util.Collections;

import io.hyperfoil.api.config.BenchmarkDefinitionException;
import io.hyperfoil.api.config.InitFromParam;
import io.hyperfoil.api.config.Name;
import io.hyperfoil.api.config.Step;
import io.hyperfoil.api.config.StepBuilder;
import io.hyperfoil.api.session.Access;
import io.hyperfoil.api.session.ResourceUtilizer;
import io.hyperfoil.api.session.Session;
import io.hyperfoil.core.builders.BaseStepBuilder;
import io.hyperfoil.core.session.SessionFactory;
import org.kohsuke.MetaInfServices;

public class TimestampStep implements Step, ResourceUtilizer {
  private final Access toVar;

  public TimestampStep(Access toVar) {
    this.toVar = toVar;
  }

  @Override
  public boolean invoke(Session session) {
    // Why there isn't any long support? This requires an unnecessary boxing I guess...
    toVar.setObject(session, String.valueOf(System.currentTimeMillis()));
    return true;
  }

  @Override
  public void reserve(Session session) {
    toVar.declareObject(session);
  }

  // Make this builder loadable as service
  @MetaInfServices(StepBuilder.class)
  // This is the step name that will be used in the YAML
  @Name("timestamp")
  public static class Builder extends BaseStepBuilder<Builder> implements InitFromParam<Builder> {
    private String toVar;

    @Override
    public Builder init(String param) {
      return toVar(param);
    }

    public Builder toVar(String toVar) {
      this.toVar = toVar;
      return this;
    }

    @Override
    public List<Step> build() {
      if (toVar == null) {
        throw new BenchmarkDefinitionException("Missing one of the required attributes!");
      }
      return Collections.singletonList(new TimestampStep(SessionFactory.access(toVar)));
    }
  }
}
