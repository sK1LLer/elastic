#!/bin/bash
working_dir="/home/nginx/tmp"
distro_array=(elasticsearch logstash kibana metricbeat filebeat auditbeat packetbeat heartbeat winlogbeat)
#rm -rf $working_dir/distribs/*
#mkdir -p "$working_dir/distribs/elasticsearch" && mkdir -p "$working_dir/distribs/kibana" && mkdir -p "$working_dir/distribs/logstash" #&& mkdir -p "$working_dir/distribs/beats"
my_version=$(cat "$working_dir/version" )
latest_version=$(wget -q https://github.com/elastic/elasticsearch/releases/latest -O - | grep "title>Release" | cut -d " " -f 5)
#latest_version="8.11.4"
echo "my_version $my_version; latest_version $latest_version"

func_download(){
mkdir -p "$working_dir"/distribs/"${distro_array[$i]}" && mkdir -p /home/nginx/webdav/"$latest_version"/"${distro_array[$i]}"
echo "downloading ${distro_array[$i]}"
if [[ ${distro_array[$i]} == winlogbeat ]]; then
  curl -s https://artifacts.elastic.co/downloads/beats/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-windows-x86_64.zip.sha512 -o $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-"$latest_version"-windows-x86_64.zip.sha512
  while [[ -n $(diff -q <(cat $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-windows-x86_64.zip.sha512 | cut -d " " -f1) <(sha512sum $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-windows-x86_64.zip | cut -d " " -f1) ) ]]; do
    curl -s https://artifacts.elastic.co/downloads/beats/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-windows-x86_64.zip.sha512 -o $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-"$latest_version"-windows-x86_64.zip.sha512
    curl -s https://artifacts.elastic.co/downloads/beats/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-windows-x86_64.zip -o $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-"$latest_version"-windows-x86_64.zip
  done
  cp $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-windows-x86_64.zip /home/nginx/webdav/"$latest_version"/"${distro_array[$i]}"/
elif [[ ${distro_array[$i]} == *"beat" ]]; then
  curl -s https://artifacts.elastic.co/downloads/beats/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb.sha512 -o $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-"$latest_version"-amd64.deb.sha512
  while [[ -n $(diff -q <(cat $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb.sha512 | cut -d " " -f1) <(sha512sum $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb | cut -d " " -f1) ) ]]; do
    curl -s https://artifacts.elastic.co/downloads/beats/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb.sha512 -o $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-"$latest_version"-amd64.deb.sha512
    curl -s https://artifacts.elastic.co/downloads/beats/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb -o $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-"$latest_version"-amd64.deb
  done
  cp $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb /home/nginx/webdav/"$latest_version"/"${distro_array[$i]}"/
else
  curl -s https://artifacts.elastic.co/downloads/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb.sha512 -o $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-"$latest_version"-amd64.deb.sha512
  while [[ -n $(diff -q <(cat $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb.sha512 | cut -d " " -f1) <(sha512sum $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb | cut -d " " -f1) ) ]]; do
    curl -s https://artifacts.elastic.co/downloads/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb.sha512 -o $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb.sha512
    curl -s https://artifacts.elastic.co/downloads/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb -o $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb
  done
  cp $working_dir/distribs/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb /home/nginx/webdav/"$latest_version"/"${distro_array[$i]}"/
fi
}

func_iterate(){
for (( i=0; i<${#distro_array[@]}; i++ )); do
  func_download
done
}

if [[ $my_version != $latest_version ]]; then
echo "our version is older, downloading"
func_iterate
echo $latest_version > "$working_dir/version"
fi
