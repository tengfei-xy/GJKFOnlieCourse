#!/bin/bash

# 作用: 课程列表页的cookie
# 链接: https://menhu.pt.ouchn.cn/site/ouchnPc/index
# 格式: "Cookie: eai-sess=xxxxxxxxx; UUkey=xxxxxxxxxx"
header_cookie_index="Cookie: eai-sess=AQIC5wM2LY4Sfcy-BX3j6oDYNS75AzvL5uZ2butf__88C38%2AAAJTSQACMDEAAlNLABM1MDQyNTA3MzAyMzA0NTcyMzQ2%2A; UUkey=f369d914bdd8f9f7dbda344c452edbc4"
# header_cookie_index="Cookie: "

# 作用: 具体课程的cookie
# 链接: https://lms.ouchn.cn/course/xxxxxxxxxxx/ng#/
# 格式: "Cookie: session=V2-60000000002-xxxxxxxx; HWWAFSESID=xxxxxx; HWWAFSESTIME=xxxxx"
header_cookie="Cookie: session=V2-10-516c4847-33af-410e-982c-a00a499d9623.MTc4ODUzMw.1699501416384.5ZFBnGeDBiDWOrvZhZ2iu-1guNk; HWWAFSESID=73db31bad14a188f595; HWWAFSESTIME=1699237059166"
# header_cookie="Cookie: "
 
# 作用: 当请求过快而学习无效时的缓冲时间
stop_second=60

# 作用: 当请求的间隔时间，但请求过快时将返回
# {  "error_msg": "Too Many Requests"}
stop_req_second=5

# 以下变量不需要变化
header_accept="Accept: application/json, text/plain, */*"
header_content_type_x_www="Content-Type: application/x-www-form-urlencoded"
header_accept_all="Accept: */*"
header_host="Host: lms.ouchn.cn"
header_host_menu="Host: menhu.pt.ouchn.cn"
header_accept_language="Accept-Language: en-US,en;q=0.9"
header_connection="Connection: keep-alive"
header_content_type="Content-Type: application/json; charset=utf-8"
header_user_agent="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15"
header_x_request="X-Requested-With: XMLHttpRequest"
header_origin="Origin: https://lms.ouchn.cn"

function log() {
    echo "$(date "+%F %T") " "$@"

}
function log() {
    echo "$(date "+%F %T") " "$@"
}
function info() {
    echo -e "$(date "+%F %T") \033[32m ${*} \033[0m"
}
function notice() {
    echo -e "$(date "+%F %T") \033[33m ${*} \033[0m"
}
function panic() {
    echo "$(date "+%F %T") " "$@"
    exit 0
}
function error() {
    echo -e "$(date "+%F %T") \033[31m ${*} \033[0m"
}
# 获取大纲
function get_modules() {
    local i
    local c
    local module_length

    header_referer=
    c=$(curl -s "https://lms.ouchn.cn/api/courses/${1}/modules" -X 'GET' -H "$header_accept" -H "$header_cookie" -H "$header_accept_language" -H "$header_user_agent" -H "$header_referer" -H "Referer: https://lms.ouchn.cn/course/${1}/learning-activity/full-screen")
    module_length=$(echo "${c}" | jq ".modules | length")

    for ((i = 0; i < module_length; i++)); do
        module_name=$(echo "$c" | jq ".modules[$i].name" -r)
        module_id=$(echo "$c" | jq ".modules[$i].id" -r)
        # get_courses_exams "$1" 

        get_courses_all_actives "$1" "$module_id" "$module_name"
        notice "---------------------------------------------------"
    done

}
# 形考作业
# function get_courses_exams() {
#     local i
#     local c
#     # https://lms.ouchn.cn/api/course/60000040841/all-activities?module_ids=[60000317335]&activity_types=learning_activities,exams,classrooms,live_records,rollcalls&no-loading-animation=true
#     c=$(curl -s "https://lms.ouchn.cn/api/course/${1}/all-activities?module_ids=\[${2}\]&activity_types=learning_activities,exams,classrooms" -X 'GET' -H "$header_accept" -H "$header_cookie" -H "$header_host" -H "$header_accept_language" -H "$header_user_agent" -H "$header_referer" -H "$header_connection" -H "Referer: https://lms.ouchn.cn/course/${1}/learning-activity/full-screen")
#     exam_length=$(echo "${c}" | jq ".exams | length")
#     test "$exam_length" -eq 0 && {
#         return
#     }

# }
# 获取二级大纲(课程信息)
function get_courses_all_actives() {
    local i
    local c
    # https://lms.ouchn.cn/api/course/60000040841/all-activities?module_ids=[60000317335]&activity_types=learning_activities,exams,classrooms,live_records,rollcalls&no-loading-animation=true
    c=$(curl -s "https://lms.ouchn.cn/api/course/${1}/all-activities?module_ids=\[${2}\]&activity_types=learning_activities,exams,classrooms" -X 'GET' -H "$header_accept" -H "$header_cookie" -H "$header_host" -H "$header_accept_language" -H "$header_user_agent" -H "$header_referer" -H "$header_connection" -H "Referer: https://lms.ouchn.cn/course/${1}/learning-activity/full-screen")

    activities_length=$(echo "${c}" | jq ".learning_activities | length")
    test "$activities_length" -eq 0 && {
        notice "大纲:${3} 无活动"
        return
    }
    log "大纲:${3} 课程类型:页面 活动数:${activities_length} 检查中..."

    for ((i = 0; i < activities_length; i++)); do
        id=$(echo "$c" | jq ".learning_activities[$i].id")
        title=$(echo "$c" | jq ".learning_activities[$i].title" -r)
        type=$(echo "$c" | jq ".learning_activities[$i].type" -r)

        check_recode "$id"
        test "$RETVAL_VALUE" == "full" && {
            info "大纲:${3} 活动名称:${title} 已完成"
            continue
        }

        case "${type}" in
        page)
            notice "大纲:${3} 活动类型:页面 活动名称:${title} 开始学习"
            enter_learn_page "${id}"
            ;;
        material)
            notice "大纲:${3} 活动类型:材料 活动名称:${title} 开始学习材料"
            enter_learn_material "${id}" "$(echo "$c" | jq ".learning_activities[$i]")"
            ;;
        forum)
            notice "大纲:${3} 活动类型:话题 活动名称:${title} 开始讨论话题"
            enter_learn_page "${id}"
            # enter_learn_forum "${id}"
            ;;
        online_video)
            notice "大纲:${3} 活动类型:视频 活动名称:${title} 开始学习视频"
            enter_learn_video "${id}"
            ;;
        exam)
            notice "大纲:${3} 活动类型:测试 活动名称:${title} 开始测试"
            enter_learn_page "${id}"
            #1
            ;;
        web_link)
            notice "大纲:${3} 活动类型:网页链接 活动名称:${title} 开始访问链接"
            enter_learn_page "${id}"
            ;;
        homework)
            notice "大纲:${3} 活动类型:作业 活动名称:${title} 开始写作业"
            enter_learn_homework "${id}"
            ;;
        vocabulary)
            notice "大纲:${3} 活动类型:词汇表 活动名称:${title} 开始查看词汇表"
            enter_learn_page "${id}"
            # enter_learn_vocabulary "${id}"
            ;;
        questionnaire)
            notice "大纲:${3} 活动类型:问卷 活动名称:${title} 开始问卷调查"
            enter_learn_page "${id}"
            #1
            ;;
        *)
            error "大纲:${3} 活动类型:${type} 活动名称:${title} 跳过,不支持"
            RETVAL_VALUE=""
            continue
            ;;
        esac

        case "$RETVAL_VALUE" in
        "Too Many Requests")
            error "下载过快，${stop_second}秒后重试"
            sleep "${stop_second}"
            i=$((i - 1))
            ;;
        esac
    done
}
function enter_learn_video() {
    local i
    local c
    c=$(curl -s "https://lms.ouchn.cn/api/course/activities-read/$1" -X 'POST' -H "${header_content_type}" -H "${header_accept_all}" -H "$header_accept_language" -H "$header_host" -H "$header_origin" -H 'Content-Length: 22' -H "$header_user_agent" -H 'Referer: https://lms.ouchn.cn/course/101045/learning-activity/full-screen' -H "${header_cookie}" -H "${header_x_request}" -d  '{"start":0,"end":9999}')
    RETVAL_VALUE=$(echo "$c" | jq ".error_msg" -r)

    sleep "${stop_req_second}"

}
function enter_learn_page() {
    local c
    local header_referer

    header_referer="Referer: https://lms.ouchn.cn/course/60000040841/learning-activity/full-screen"
    c=$(curl -s "https://lms.ouchn.cn/api/course/activities-read/${1}" -X 'POST' -H 'Content-Length: 2' -H "$header_content_type" -H "$header_accept_all" -H "$header_accept_language" -H "$header_host" -H "$header_origin" -H "$header_referer" -H "$header_user_agent" -H "$header_cookie" -H "$header_x_request" -d  '{}')
    RETVAL_VALUE=$(echo "$c" | jq ".error_msg" -r)

    sleep "${stop_req_second}"

}
function enter_learn_forum() {
    local c
    local random_string
    local id
    local data

    random_string=$(head -1 /dev/urandom | od -x | awk '{print $2$3$4$5$6}' | head -n1)
    c=$(curl -s "https://lms.ouchn.cn/api/forum/${1}/category?fields=id,title,activity(id,sort,module_id,syllabus_id,start_time,end_time,is_started,is_closed,data,can_show_score,score_percentage,title,prerequisites,submit_by_group,group_set_id,group_set_name,imported_from,parent_id),referrer_type" -X 'GET' -H "$header_content_type" -H "$header_accept" -H "$header_accept_language" -H "$header_host" -H "$header_origin" -H "$header_cookie" -H "$header_user_agent" -H 'Referer: https://lms.ouchn.cn/course/101045/learning-activity/full-screen')
    id=$(echo "$c" | jq ".topic_category.id")
    data="{\"title\":\"${random_string}\",\"content\":\"<p>${random_string}<br></p>\",\"uploads\":[],\"category_id\":${id}}"

    c=$(curl -s 'https://lms.ouchn.cn/api/topics' -X 'POST' -H "$header_content_type" -H "$header_accept" -H "$header_accept_language" -H "$header_host" -H "$header_origin" -H "$header_cookie" -H "$header_user_agent" -H 'Referer: https://lms.ouchn.cn/course/101045/learning-activity/full-screen' -H "Content-Length: ${#data}" -d  "${data}")
    RETVAL_VALUE=$(echo "$c" | jq ".error_msg" -r)

    sleep "${stop_req_second}"

}
function enter_learn_homework() {
    local data
    local c
    local random_string

    random_string=$(head -1 /dev/urandom | od -x | awk '{print $2$3$4$5$6}' | head -n1)
    data="{\"comment\":\"<p>${random_string}</p>\",\"uploads\":[],\"slides\":[],\"is_draft\":false,\"mode\":\"normal\"}"
    c=$(curl -s "https://lms.ouchn.cn/api/course/activities/${1}/submissions" -X 'POST' -H "$header_content_type" -H "$header_accept" -H "$header_accept_language" -H "$header_host" -H "$header_origin" -H "$header_cookie" -H "$header_user_agent" -H 'Referer: https://lms.ouchn.cn/course/101045/learning-activity/full-screen' -H "Content-Length: ${#data}" -d  "${data}")
    RETVAL_VALUE=$(echo "$c" | jq ".error_msg" -r)

    sleep "${stop_req_second}"

}
function enter_learn_material() {
    local data
    local i
    local c
    local upload_id
    uploads_length=$(echo "${2}" | jq ".uploads | length")
    for ((i = 0; i < uploads_length; i++)); do
        upload_id=$(echo "${2}" | jq ".uploads[$i].id")
        data="{\"upload_id\":${upload_id}}"

        c=$(curl -s "https://lms.ouchn.cn/api/course/activities-read/${1}" -X 'POST' -H "$header_content_type" -H "$header_accept" -H "$header_accept_language" -H "$header_host" -H "$header_origin" -H "$header_cookie" -H "$header_user_agent" -H 'Referer: https://lms.ouchn.cn/course/101045/learning-activity/full-screen' -H "Content-Length: ${#data}" -d  "${data}")
        RETVAL_VALUE=$(echo "$c" | jq ".error_msg" -r)

        case "$RETVAL_VALUE" in
        "Too Many Requests")
            error "下载过快，${stop_second}秒后重试"
            sleep "${stop_second}"
            i=$((i - 1))
            ;;
        esac
        sleep "${stop_req_second}"
    done
}

function study_recode() {
    local c
    local c_length
    local i
    local completeness

    notice "载入学习进度"
    c=$(curl -s "https://lms.ouchn.cn/api/course/${1}/activity-reads-for-user" -X 'GET' -H "$header_content_type" -H "$header_accept_all" -H "$header_accept_language" -H "$header_host" -H "$header_origin" -H "$header_user_agent" -H "$header_cookie" -H "$header_x_request" -H "Referer: https://lms.ouchn.cn/course/$1/ng")
    c_length=$(echo "${c}" | jq ".activity_reads| length")
    data_recoder=""
    for ((i = 0; i < c_length; i++)); do
        # completeness返回:
        # part = 完成部分
        # full = 已完成
        # null = 未完成
        completeness=$(echo "${c}" | jq ".activity_reads[$i].completeness" -r)

        test "$completeness" == "full" && {
            data_recoder="$data_recoder$(echo "${c}" | jq ".activity_reads[$i].activity_id"),"
        }
    done

}

# 作用: 检查完成情况

function check_recode() {
    RETVAL_VALUE=null
    echo "$data_recoder" | grep "$1" >/dev/null 2>&1 && RETVAL_VALUE="full"
}
function check_completeness() {
    local d

    d=$(curl -s "https://lms.ouchn.cn/api/course/$1/my-completeness" -X 'GET' -H "$header_content_type" -H "$header_accept_all" -H "$header_accept_language" -H "$header_host" -H "$header_origin" -H "$header_user_agent" -H "$header_cookie" -H "$header_x_request" -H "Referer: https://lms.ouchn.cn/course/$1/ng")
    study_completeness=$(echo "$d" | jq ".study_completeness" -r)
    log "完成进度 ${study_completeness}%"
}
function get_subject() {
    local d

    d=$(curl -s "https://lms.ouchn.cn/api/courses/$1?fields=id,name,start_date,end_date,course_code,subject_code,credit,is_child,is_master,has_instruction_team,course_attributes(student_count,teaching_class_name,data),cover,academic_year,semester,public_scope,learning_mode,teaching_mode,score_published,students_count,compulsory,syllabus_enabled,imported_from,course_type,audit_status,display_name,classroom_schedule,second_name,department(id,code,name),grade(id,name),klass(id,name),instructors(id,user_no,email,avatar_big_url,avatar_small_url,name,portfolio_url),org(is_enterprise_or_organization,is_transfer_arrears,allow_digital_teaching_material)" -X 'GET' -H "$header_content_type" -H "$header_accept_all" -H "$header_accept_language" -H "$header_host" -H "$header_origin" -H "$header_user_agent" -H "$header_cookie" -H "$header_x_request" -H "Referer: https://lms.ouchn.cn/course/$1/ng")
    subject_name=$(echo "$d" | jq ".display_name" -r)
    log "科目名: ${subject_name}"
}
function get_subject_list() {
    local header_r
    local c
    local i
    local name
    local completeness
    header_r="Referer: https://menhu.pt.ouchn.cn/site/ouchnPc/index"
    c=$(curl -s 'https://menhu.pt.ouchn.cn/ouchnapp/wap/course/xskc-pc' -X 'POST' -H "$header_content_type_x_www" -H "${header_accept}" -H "$header_accept_language" -H "$header_host_menu" -H "$header_origin" -H 'Content-Length: 24' -H "$header_user_agent" -H "$header_r" -H "$header_cookie_index" -H "$header_x_request" --data 'tab=&page=1&page_size=20')
    test "$(echo "$c" | jq ".e")" == "10013" && {
        error "cookie已失效"
        exit 0
    }

    subject_list_length=$(echo "$c" | jq ".d.list | length")
    for ((i = 0; i < subject_list_length; i++)); do
        name=$(echo "$c" | jq ".d.list[$i].name" -r)
        completeness=$(echo "$c" | jq ".d.list[$i].completeness" -r)
        echo -e "$((i + 1))、${name}    \t 进度:${completeness}%"
    done
    echo
    read -r -p "选择课程序号:" seq
    SUBJECT_ID=$(echo "$c" | jq ".d.list[$((seq - 1))].url" | awk -F "/" '{print($5)}')

}
main() {
    get_subject_list
    get_subject "$SUBJECT_ID"
    check_completeness "$SUBJECT_ID"
    study_recode "$SUBJECT_ID"
    get_modules "$SUBJECT_ID"
}
main
