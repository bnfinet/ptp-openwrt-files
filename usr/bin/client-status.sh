#!/bin/sh
STA=/proc/net/madwifi/ath0/associated_sta

ncusers()
{
iptables -t mangle -nxvL NoCat | grep MAC | awk '{print $11,$8,$2}'
}

usercount()
{
ncusers | wc -l
}

cmb() 
{
ncusers | while read i; do
  grep -A1 -i $(echo $i|awk '{print $1}') $STA | tail -1| grep -o "[0-9].*" | xargs echo $i
done
cat $STA | egrep -A1 -o '(..:..:..:..:..:..|rssi.*)'| sed -e 's/rssi \(.*\)/\1\\\n/g' | grep -v last | xargs | sed '/^$/d' | tr 'a-f' 'A-F' | awk '{print $1,"0","0",$2}'
}

sta()
{
cmb | sort -r | uniq -w17 | awk '{print $3,$1,$2,$4}' | sort -nr | awk '{print $2,$3,$1,$4}' | while read i; do 
  D=`echo $i | awk '{print $3}'`
  if [ $D -ge 1048576 ]; then 
      echo $D | awk '{ sum+=$1/1024^2 }; END { printf ("%dM", sum )}'
    elif [ $D -le 1048575 -a $D -ge 1024 ]; then
      echo $D | awk '{ sum+=$1/1024 }; END { printf ("%dK", sum )}'
    else echo $D
  fi | xargs echo `echo $i | awk '{print $1,$2,$4}'`; done 2>/dev/null | awk '{print $1,$2,$4,$3}'
}

sig()
{
#s=`sta | sed '/^$/d' | grep -i "$1" | awk '{print $4}'`
s=$1
if [ $s ]; then
  if [ $s -ge 30 ]; then
      echo sig-100.gif
    elif [ $s -le 29 -a $s -ge 25 ]; then
      echo sig-75.gif
    elif [ $s -le 24 -a $s -ge 20 ]; then
      echo sig-50.gif
    elif [ $s -le 19 ]; then
      echo sig-25.gif
  fi
else
  echo sig-0.gif
fi
}

html()
{
T=$(grep -o "<title.*title>" /www/splash.html)
T1=$(echo "$T" | sed 's:<title>Personal Telco Project - \(.*\)</title>:\1:')
echo -e "<html>\n<head>\n$T"
echo -e "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>"
echo -e "  <link rel=\"stylesheet\" type=\"text/css\" href=\"main.css\"/>"
echo -e "  <link rel=\"shortcut icon\" href=\"favicon.ico\"/>"
echo -e "</head>\n<body>"
echo -e "<div class=\"header\"><div class=\"headcontent\"><div class=\"tower\"><img src=\"images/ptp-logo.png\" width=\"41\" height=\"80\" alt=\"tower logo\"/></div><div class=\"toptext\"><img src=\"images/ptp-masthead.gif\" width=\"240\" height=\"27\" alt=\"personal telco project\"/></div><div class=\"topnav\">$T1</div></div></div><div class=\"body\"><div class=\"content\" style=\"margin-left:auto;margin-right:auto\">"
echo -e "<p><b>Uptime</b>:$(uptime)</p>"
echo -e "<p><b>Status</b>: $(usercount) users active at $(date)</p>"
echo -e "<table border="1" cellpadding="5">\n<tr><th>Client</th><th>MAC Address</th><th>Usage</th><th>Signal</th></tr>"
sta | sed '/^$/d' | while read i; do sig `echo $i|awk '{print $4}'`| xargs echo `echo $i | awk '{print $1,$2,$3}'` | sed 's^\(..\):\(..\):\(..\):\(..\):..:\(..\) \(.*\) \(.*\) \(.*\)^<tr><td align="center">\6</td><td align="center"><a href="http://standards.ieee.org/cgi-bin/ouisearch?\1\2\3">\1:\2:\3:\4:xx:\5</a></td><td align="right">\7</td><td align="center"><img src="images/\8"/></td></td>^'; done
echo -e "</table></div>\n</div>\n</body>\n</html>"
}

hlp()
{
echo -e "<nocatstatus.sh> - usage: nocatstatus.sh -(option)"
echo -e "       client-status.sh is a script to parse client information"
echo -e "       "
echo -e "       Options"
echo -e "-c     - count total users"
echo -e "-t     - output current user table (for status page integration)"
echo -e "-o     - last connection date string (not yet)"
echo -e "-h     - this"
}

case $1 in
"" ) hlp ;;
"-c" ) usercount ;;
"-m" ) cmb ;;
"-t" ) html ;;
"-o" ) sta ;;
"-h" ) hlp ;;
"-help" ) hlp ;;
esac
