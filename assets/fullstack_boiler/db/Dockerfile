FROM postgres:11.4-alpine

WORKDIR /var/lib/postgres

COPY ./docker-entrypoint.sh .
COPY ./initdb.sql .
COPY ./data/test_db.sql .
COPY ./config ./config

ENV DB_USER=$STI_DB_USER
ENV DB_PASSWORD=$STI_DB_PASSWORD
ENV DB_PORT=$STI_DB_PORT
ENV DB_NAME=$STI_DB_NAME

RUN chmod +x docker-entrypoint.sh && chown -R postgres:postgres /var/lib/postgres && ls -lrth && ls -lrth config && pwd

USER postgres
ENTRYPOINT ["./docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres", "-c", "config_file=config/postgresql.conf"]
