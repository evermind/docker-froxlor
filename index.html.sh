#!/bin/bash

cat << EOF
<html>
<body>
<h1>Public repo for dockerized froxlor helm chart</h1>
<h2>Installation</h2>
<p>
<pre>
helm repo add froxlor https://evermind.github.io/docker-froxlor/
helm install froxlor/froxlor
</pre>
</p>
<h2>Available versions</h2>
<ul>
EOF

grep index.yaml -e "version:" | awk -F': ' '{print "<li>"$2"</li>"}' | sort -n -r

cat << EOF
</ul>
</body>
</html>
EOF

