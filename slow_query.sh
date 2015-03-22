REMOTE_DB_HOST="<remote hostname/ip>"
REMOTE_DB_HOST_SHORT="nickname"
SLOW_LOG_PATH="/tmp/mysql.slow_log.log"
REMOTE_DB_PASS="<dbpwd>"
REMOTE_DB_USER="<dbuser>"
VIEWER_DB_HOST="localhost"
VIEWER_DB_USER="anemometer"
VIEWER_DB_PASS="<anemometer-pwd>"

if [[ ! -f ${SLOW_LOG_PATH} ]]; then
    echo "downloading slow_log: ${SLOW_LOG_PATH}..."
/usr/local/bin/mysql -u ${REMOTE_DB_USER} -p${REMOTE_DB_PASS} -h $REMOTE_DB_HOST -D mysql \
  -s -r -e "SELECT CONCAT('# Time: ', DATE_FORMAT(start_time, '%y%m%d %H%i%s'), '\n', \
  '# User@Host: ', user_host, '\n', '# Query_time: ', TIME_TO_SEC(query_time), ' Lock_time: ', \
  TIME_TO_SEC(lock_time), ' Rows_sent: ', rows_sent, ' Rows_examined: ', rows_examined, '\n', sql_text, ';' ) \
  FROM mysql.slow_log" > ${SLOW_LOG_PATH}

# /usr/local/bin/pt-query-digest ${SLOW_LOG_PATH} > slow_query_report.txt
fi

echo "importing slow_log: ${SLOW_LOG_PATH}..."
/usr/local/bin/pt-query-digest --user=${VIEWER_DB_USER} --password=${VIEWER_DB_PASS} \
                    --review h=${VIEWER_DB_HOST},D=slow_query_log,t=global_query_review \
                                      --history h=${VIEWER_DB_HOST},D=slow_query_log,t=global_query_review_history \
                                                        --no-report --limit=0% \
                  --filter=" \$event->{Bytes} = length(\$event->{arg}) and \$event->{hostname}=\"$REMOTE_DB_HOST_SHORT\"" \
                    ${SLOW_LOG_PATH}
