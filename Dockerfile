# Author: Jorge Ramirez

FROM library/centos:7
MAINTAINER Jorge Ramirez "jorgeramirez1990@gmail.com"

RUN yum -y update
RUN yum -y install wget deltarpm bzip2
# download latest release
RUN wget https://www.postgres-xl.org/downloads/postgres-xl-9.5r1.6.tar.bz2
RUN tar -jxvf postgres-xl-9.5r1.6.tar.bz2
WORKDIR postgres-xl-9.5r1.6

RUN yum group install -y "Development Tools"
RUN yum install -y readline-devel zlib-devel libuuid uuid-devel

RUN ./configure --with-ossp-uuid
RUN make
USER root

RUN make install
WORKDIR contrib
RUN make install

# Setup one coordinator, two data nodes and one GTM
RUN adduser postgres
RUN mkdir /usr/local/pgsql/data_coord1
RUN mkdir /usr/local/pgsql/data_datanode_1
RUN mkdir /usr/local/pgsql/data_datanode_2
RUN mkdir /usr/local/pgsql/data_datanode_3
RUN mkdir /usr/local/pgsql/data_gtm

ADD resources/start-cluster.sh /usr/bin/start-cluster.sh
RUN chmod +x /usr/bin/start-cluster.sh
ADD resources/test-db.sql /home/postgres/test-db.sql

RUN chown postgres /usr/local/pgsql/data_coord1
RUN chown postgres /usr/local/pgsql/data_datanode_1
RUN chown postgres /usr/local/pgsql/data_datanode_2
RUN chown postgres /usr/local/pgsql/data_datanode_3
RUN chown postgres /usr/local/pgsql/data_gtm
RUN chown postgres /usr/bin/start-cluster.sh

RUN cp /usr/local/pgsql/share/pg_hba.conf.sample /usr/local/pgsql/share/pg_hba.conf
RUN echo "host all  all    0.0.0.0/0  trust" >> /usr/local/pgsql/share/pg_hba.conf

RUN cp /usr/local/pgsql/share/postgresql.conf.sample /usr/local/pgsql/share/postgresql.conf
RUN cp /usr/local/pgsql/share/gtm.conf.sample /usr/local/pgsql/share/gtm.conf
RUN cp /usr/local/pgsql/share/gtm_proxy.conf.sample /usr/local/pgsql/share/gtm_proxy.conf
RUN echo "listen_addresses='*'" >> /usr/local/pgsql/share/postgresql.conf
RUN echo "listen_addresses='*'" >> /usr/local/pgsql/share/gtm.conf
RUN echo "listen_addresses='*'" >> /usr/local/pgsql/share/gtm_proxy.conf

USER postgres

RUN /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data_coord1 --nodename coord1
RUN /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data_datanode_1 --nodename datanode_1
RUN /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data_datanode_2 --nodename datanode_2
RUN /usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data_datanode_3 --nodename datanode_3
RUN /usr/local/pgsql/bin/initgtm -D /usr/local/pgsql/data_gtm -Z gtm
RUN echo "export PATH=$PATH:/usr/local/pgsql/bin" >> /home/postgres/.bashrc

EXPOSE 5432

RUN echo "listen_addresses='*'" >> /usr/local/pgsql/data_coord1/postgresql.conf
RUN echo "host all  all    0.0.0.0/0  trust" >> /usr/local/pgsql/data_coord1/pg_hba.conf

ADD init.sql /pgxl-initdb.d/
User root

RUN echo root:admin | chpasswd

User postgres
CMD ["/usr/bin/start-cluster.sh"]
