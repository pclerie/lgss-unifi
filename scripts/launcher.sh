#! /bin/sh

${SNAP}/usr/lib/jvm/java-17-openjdk-${SNAP_ARCH}/bin/java \
  -Dfile.encoding=UTF-8 \
  -Djava.awt.headless=true \
  -Dapple.awt.UIElement=true \
  -Dunifi.core.enabled=false \
  -Xmx1024M \
  -XX:+UseParallelGC \
  -XX:+ExitOnOutOfMemoryError \
  -XX:+CrashOnOutOfMemoryError \
  -XX:ErrorFile=/usr/lib/unifi/logs/unifi_crash.log \
  -Xlog:gc:logs/gc.log:time:filecount=2,filesize=5M \
  --add-opens java.base/java.lang=ALL-UNNAMED \
  --add-opens java.base/java.time=ALL-UNNAMED \
  --add-opens java.base/java.io=ALL-UNNAMED \
  --add-opens java.base/sun.security.util=ALL-UNNAMED \
  --add-opens java.rmi/sun.rmi.transport=ALL-UNNAMED \
  -jar /usr/lib/unifi/lib/ace.jar start
