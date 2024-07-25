#!/bin/sh

# slack的webhook地址
webhook_url='https://hooks.slack.com/services/xxxxxxxxxxxxx'

#此处可以不管，等Emby更新再用
pinyin_url="http://127.0.0.1"

#时间
#$(date "+%Y.%m.%d %H:%M")

#TMDB API
Tmdb_api_key="xxxxxxxxxx"

get_new_str()
{
    len_old_str=${#overview}
    if [ $len_old_str -gt 120 ]; then
        new_text="${overview:0:120}...."
    else
        new_text=$overview
    fi
}

get_img_url()
{
    RES_TMDB=$("${TOOLS_DIR}"/curl -s 'https://api.themoviedb.org/3/movie/'${TMDB_ID}'?api_key='${Tmdb_api_key}'')
    IMG_PATH=$(echo ${RES_TMDB} | "${TOOLS_DIR}"/jq -r '.backdrop_path')
    IMG_PUSH=""	
    if [ "$IMG_PATH" = ""  ]; then
        IMG_PUSH="https://s2.loli.net/2022/03/17/amj947HFM3I5TPl.jpg"
    else
        IMG_PUSH="https://image.tmdb.org/t/p/w500${IMG_PATH}"
    fi
}

get_episode_url()
{
    SERIES_TMDB=$("${TOOLS_DIR}"/curl -s 'https://api.themoviedb.org/3/tv/'${TMDB_ID}'?api_key='${Tmdb_api_key}'')
    IMG_PATH=$(echo ${SERIES_TMDB} | "${TOOLS_DIR}"/jq -r '.backdrop_path')
    IMG_PUSH=""	
    if [ "$IMG_PATH" = ""  ]; then
        IMG_PUSH="https://s2.loli.net/2022/03/17/amj947HFM3I5TPl.jpg"
    else
        IMG_PUSH="https://image.tmdb.org/t/p/w500${IMG_PATH}"
    fi
}

get_item_format()
{
    result=$(echo ${Item_Path} | sed -n "s/.*\(1080p\|2160p\|4k\|720p\).*/\1/p")
	if [ "$result" = "" ]; then
	   item_format="未知分辨率"
	elif [ "$result" = "2160p" -o "$result" = "4k" ]; then
	   item_format="4k（2160p）"
	else
	   item_format=${result}
	fi
}

webhook() {
    "${TOOLS_DIR}"/curl -s -X POST "$webhook_url" -H "Content-Type: application/json" -d "$1"
	rm json.json
}

pinyinhook(){
    "${TOOLS_DIR}"/curl -s -X POST "$pinyin_url" -H "Content-Type: application/json" -d "$1"
}

BASE_ROOT=$(cd "$(dirname "$0")"; pwd)
TOOLS_DIR=${BASE_ROOT}/tools

if [ $1 == Movie ]; then
# 1= 类型，2=电影名字（年份），3=Emby中TMDB ID，4=入库的库名字，5=电影简介，MEDIA_TEXT=格式化后的简介（120字符-非中文120字，超过后略缩为...），6=文件路径（主要为获取名字后面的分辨率）
    TYPE=$1
	NAME=$2
	TMDB_ID=$3
	Library_Path=$4
	overview="$(echo "$5" | sed 's/^[ ]*//g')"
	Item_Path=$6
	get_new_str
	get_img_url
	MEDIA_TEXT=$new_text
	get_item_format
	MEIDA_FORMAT=$item_format
	echo "{\"text\": \":small_blue_diamond: 新入库$Library_Path：$NAME\",\"blocks\":[{\"type\":\"image\",\"image_url\":\"$IMG_PUSH\",\"alt_text\":\"$NAME\"},{\"type\":\"rich_text\",\"elements\":[{\"type\":\"rich_text_section\",\"elements\":[{\"type\":\"text\",\"text\":\"新增$Library_Path：\"},{\"type\":\"text\",\"text\":\"$NAME\",\"style\":{\"bold\":true}},{\"type\":\"text\",\"text\":\"\n入库时间：$(date "+%Y.%m.%d %H:%M")\n入库类型：$Library_Path\n媒体格式：$MEIDA_FORMAT\n剧情简介：$MEDIA_TEXT\"}]}]},{\"type\":\"divider\"}]}" > json.json
	webhook "@json.json"
elif [ $1 == Episode ]; then
# 1= 类型，2=剧集名字，3=季号，4=集号，5=分集名字，6=TMDB ID编号，7=入库的库名字，8=简介，MEDIA_TEXT=格式化后的简介（120字符-非中文120字，超过后略缩为...），9=文件路径（主要为获取名字后面的分辨率）
    TYPE=$1
	SERIES_NAME=$2
	SEASON_NUMBER=$3
	EPISODE_NUMBER=$4
	EPISODE_NAME=$5
	TMDB_ID=$6
	Library_Path=$7
	overview=$8
	Item_Path=$9
    get_new_str
	get_episode_url
	MEDIA_TEXT=$new_text
	get_item_format
	MEIDA_FORMAT=$item_format
    echo "{\"text\":\":small_blue_diamond: 新入库$Library_Path：$SERIES_NAME【第$SEASON_NUMBER季-第$EPISODE_NUMBER集】\",\"blocks\":[{\"type\":\"image\",\"image_url\":\"$IMG_PUSH\",\"alt_text\":\"$SERIES_NAME\"},{\"type\":\"rich_text\",\"elements\":[{\"type\":\"rich_text_section\",\"elements\":[{\"type\":\"text\",\"text\":\"新增$Library_Path：\"},{\"type\":\"text\",\"text\":\"$SERIES_NAME\",\"style\":{\"bold\":true}},{\"type\":\"text\",\"text\":\"\n剧集序号：\"},{\"type\":\"text\",\"text\":\"第$SEASON_NUMBER季 - 第$EPISODE_NUMBER集\"},{\"type\":\"text\",\"text\":\"\n单集名称：\"},{\"type\":\"text\",\"text\":\"$EPISODE_NAME\",\"style\":{\"bold\":true}},{\"type\":\"text\",\"text\":\"\n入库时间：$(date "+%Y.%m.%d %H:%M")\n入库类型：$Library_Path\n媒体格式：$MEIDA_FORMAT\n单集简介：$MEDIA_TEXT\"}]}]},{\"type\":\"divider\"}]}" > json.json
	webhook "@json.json"
elif [ $1 == BoxSet ]; then
# 1=合集类型，2=合集ID
    PINYIN_TYPE=$1
	PINYIN_ID=$2
    pinyinhook "{\"ItemId\":\"$2\",\"ItemType\":\"$1\"}"
fi
