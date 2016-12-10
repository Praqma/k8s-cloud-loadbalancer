FROM httpd:2.4


RUN  mkdir /certs
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY index.html /usr/local/apache2/htdocs/index.html
COPY server.key /certs/
COPY server.crt /certs/
COPY server.csr /certs/

EXPOSE 80 443
