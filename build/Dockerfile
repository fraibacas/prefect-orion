ARG PREFECT_BASE_IMAGE
FROM ${PREFECT_BASE_IMAGE}
ENV PREFECT_BASE_IMAGE=${PREFECT_BASE_IMAGE}

COPY ./build/requirements.txt /tmp/requirements.txt

RUN apt update && \
    apt install -y vim && \
    pip install psycopg2-binary s3fs

RUN pip install --no-cache-dir -r /tmp/requirements.txt
