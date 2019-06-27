FROM centos:7.5.1804
ARG TYPE=releases
ARG PKG=hengshi-sense-2.4.0.zip
ARG DK=hengshi-sense.Dockerfile
ARG ENTRYPOINT=docker-entrypoint.sh
ENV HSHOME=/opt/hengshi HSDATA=/opt/hsdata \
FIX_GP_HOST=fix-hostname.sh TMP=/tmp

COPY CentOS-Base.repo $FIX_GP_HOST $ENTRYPOINT $PKG* $TMP/

RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup \
&& mv ${TMP}/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo \
&& yum makecache \
&& yum install -y sudo wget unzip \
&& useradd -m hengshi \
&& chmod 755 /etc/sudoers \
&& echo "hengshi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
&& chmod 440 /etc/sudoers \
&& mv ${TMP}/${ENTRYPOINT} / \
&& chown 755 /${ENTRYPOINT} \
&& mv ${TMP}/$FIX_GP_HOST / \
&& chown 755 /$FIX_GP_HOST \
&& mkdir -p ${HSHOME}/logs \
&& mkdir -p ${HSDATA}/conf \
&& chown hengshi:hengshi ${HSDATA} -R \
&& chown hengshi:hengshi ${HSHOME} -R \
&& cd $TMP && { test -e ${PKG} || wget https://download.hengshi.io/${TYPE}/${PKG}; } \
&& mkdir unpack \
&& unzip -qd unpack ${PKG} \
&& cd unpack \
&& sed -i -e 's#local CAPACITY_THRESHOLD=10000000#local CAPACITY_THRESHOLD=1000000#' hs_install \
&& eval $(grep -E '^GREENPLUM=' bin/common.sh) \
&& sed -i '/SEGMENT_NUM=$((CPU_NUM/a\ SEGMENT_NUM=1' lib/$GREENPLUM/gpdb/bin/install-cluster.sh \
&& sed -i '/function checkHostSysConfig() {/a\ return 0;' lib/$GREENPLUM/gpdb/bin/util.sh \
&& su hengshi -c "./hs_install -p ${HSHOME} -s t" \
&& cp ${HSHOME}/conf/hengshi-sense-env.sh.sample ${HSHOME}/conf/hengshi-sense-env.sh \
&& sed -i -e "$ a HS_HENGSHI_DATA=${HSDATA}" -e "$ a HS_BACKUP_DIR=${HSDATA}/backup" ${HSHOME}/conf/hengshi-sense-env.sh \
&& chown hengshi:hengshi ${HSHOME} -R \
&& su hengshi -c "${HSHOME}/bin/hengshi-sense-bin init-os deps" \
&& cd $TMP && rm $PKG unpack -rf \
&& yum clean all \
&& rm -rf /var/cache/yum

USER hengshi
WORKDIR /home/hengshi/
VOLUME ${HSDATA}

EXPOSE 8080
ENTRYPOINT ["/docker-entrypoint.sh"]
