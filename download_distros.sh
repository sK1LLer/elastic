#!/bin/bash

working_dir="/root/nginx"
distro_array=(elasticsearch logstash kibana metricbeat filebeat auditbeat packetbeat heartbeat winlogbeat)
#distro_array=(heartbeat)

my_version=$(cat "$working_dir/tmp/version" )
latest_version=$(wget -q https://github.com/elastic/elasticsearch/releases/latest -O - | grep "title>Release" | cut -d " " -f 5)
#latest_version="8.11.4"
echo "my_version is:\"$my_version\"; latest_version is:\"$latest_version\""

func_curl(){
curl -s --output-dir $working_dir/tmp/distribs/$latest_version -O "$sha_url"
curl -s --output-dir $working_dir/tmp/distribs/$latest_version -O "$dl_url"
}

func_download(){
mkdir -p "$working_dir"/tmp/distribs/"$latest_version" && mkdir -p $working_dir/webdav/"$latest_version"
echo "downloading ${distro_array[$i]}"
if [[ ${distro_array[$i]} == winlogbeat ]]; then
  dl_url="https://artifacts.elastic.co/downloads/beats/${distro_array[$i]}/${distro_array[$i]}-$latest_version-windows-x86_64.zip"
  sha_url="$dl_url.sha512"
  curl -s --output-dir $working_dir/tmp/distribs/$latest_version -O "$sha_url"
  while [[ -n $(diff -q <(cat $working_dir/tmp/distribs/"$latest_version"/"${distro_array[$i]}"-$latest_version-windows-x86_64.zip.sha512 | cut -d " " -f1) <(sha512sum $working_dir/tmp/distribs/"$latest_version"/"${distro_array[$i]}"-$latest_version-windows-x86_64.zip | cut -d " " -f1) ) ]]; do
    func_curl
  done
elif [[ ${distro_array[$i]} == *"beat" ]]; then
  dl_url="https://artifacts.elastic.co/downloads/beats/${distro_array[$i]}/${distro_array[$i]}-$latest_version-amd64.deb"
  sha_url="$dl_url.sha512"
  curl -s --output-dir $working_dir/tmp/distribs/$latest_version -O "$sha_url"
  while [[ -n $(diff -q <(cat $working_dir/tmp/distribs/"$latest_version"/"${distro_array[$i]}"-$latest_version-amd64.deb.sha512 | cut -d " " -f1) <(sha512sum $working_dir/tmp/distribs/"$latest_version"/"${distro_array[$i]}"-$latest_version-amd64.deb | cut -d " " -f1) ) ]]; do
    func_curl
  done
else
  dl_url="https://artifacts.elastic.co/downloads/"${distro_array[$i]}"/"${distro_array[$i]}"-$latest_version-amd64.deb"
  sha_url="$dl_url.sha512"
  curl -s --output-dir $working_dir/tmp/distribs/$latest_version -O "$sha_url"
  while [[ -n $(diff -q <(cat $working_dir/tmp/distribs/"$latest_version"/"${distro_array[$i]}"-$latest_version-amd64.deb.sha512 | cut -d " " -f1) <(sha512sum $working_dir/tmp/distribs/"$latest_version"/"${distro_array[$i]}"-$latest_version-amd64.deb | cut -d " " -f1) ) ]]; do
    func_curl
  done
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
for file in $(ls "$working_dir"/tmp/distribs/"$latest_version"/ | grep -v "sha512"); do mv "$working_dir"/tmp/distribs/"$latest_version"/$file "$working_dir"/webdav/"$latest_version"/ ; done
echo $latest_version > "$working_dir/tmp/version"
fi
