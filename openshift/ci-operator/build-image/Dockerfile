# Dockerfile to bootstrap build and test in openshift-ci

FROM registry.ci.openshift.org/openshift/release:golang-1.17 as builder

# Add kubernetes repository
RUN wget --no-verbose https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-4.10/openshift-client-linux.tar.gz && \
    tar xvzf openshift-client-linux.tar.gz && \
    mv oc /bin/oc && \
    mv kubectl /bin/kubectl

# Allow runtime users to add entries to /etc/passwd
RUN chmod g+rw /etc/passwd

FROM registry.ci.openshift.org/openshift/python:3.9-ubi8

COPY --from=builder /bin/kubectl /bin/kubectl
COPY --from=builder /bin/oc /bin/oc
