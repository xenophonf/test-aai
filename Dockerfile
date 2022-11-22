FROM satosa AS custom_code
# build custom micro services
COPY --chown=satosa:satosa src /home/satosa/src
RUN cd /home/satosa/src/static_content; pip install --user .

FROM satosa
COPY --from=custom_code /home/satosa/.local /home/satosa/.local
COPY --chown=satosa:satosa *.yaml /etc/satosa/
COPY --chown=satosa:satosa plugins /etc/satosa/plugins
