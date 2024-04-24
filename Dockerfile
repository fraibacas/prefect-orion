ARG PREFECT_BASE_IMAGE
FROM ${PREFECT_BASE_IMAGE}
ENV PREFECT_BASE_IMAGE=${PREFECT_BASE_IMAGE}


RUN apt update && \
    apt install -y vim && \
    pip install psycopg2-binary s3fs