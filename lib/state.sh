#!/bin/sh
# shellcheck disable=SC2034

[ -n "${KUBE_REVAMPED_STATE_LOADED:-}" ] && return 0
KUBE_REVAMPED_STATE_LOADED=1

KUBE_REVAMPED_SETTINGS='menu_context_key	M-k
menu_namespace_key
popup_key
interval	10
color	#[fg=blue]
prod_pattern
prod_color	#[fg=red]
warn_color	#[fg=yellow]
warn_icon	?
icon
hide_default	0
show_cluster	0
show_namespace	1
show_user	0
probe_reach	0
probe_nodes	0
probe_pods	0
popup_command	k9s
popup_width	80%
popup_height	80%'
KUBE_REVAMPED_NAMES='menu_context_key menu_namespace_key popup_key interval color prod_pattern prod_color warn_color warn_icon icon hide_default show_cluster show_namespace show_user probe_reach probe_nodes probe_pods popup_command popup_width popup_height'
KUBE_REVAMPED_CARRIED='interval color prod_pattern prod_color warn_color warn_icon icon hide_default show_cluster show_namespace show_user probe_reach probe_nodes probe_pods popup_command popup_width popup_height'
KUBE_REVAMPED_SWITCHES='hide_default show_cluster show_namespace show_user probe_reach probe_nodes probe_pods'
KUBE_REVAMPED_LIVE='value value_ts value_lock value_lock_ts dangling cluster user reach nodes pods'
KUBE_REVAMPED_S_menu_context_key='M-k'
KUBE_REVAMPED_S_menu_namespace_key=''
KUBE_REVAMPED_S_popup_key=''
KUBE_REVAMPED_S_interval='10'
KUBE_REVAMPED_S_color='#[fg=blue]'
KUBE_REVAMPED_S_prod_pattern=''
KUBE_REVAMPED_S_prod_color='#[fg=red]'
KUBE_REVAMPED_S_warn_color='#[fg=yellow]'
KUBE_REVAMPED_S_warn_icon='?'
KUBE_REVAMPED_S_icon=''
KUBE_REVAMPED_S_hide_default='0'
KUBE_REVAMPED_S_show_cluster='0'
KUBE_REVAMPED_S_show_namespace='1'
KUBE_REVAMPED_S_show_user='0'
KUBE_REVAMPED_S_probe_reach='0'
KUBE_REVAMPED_S_probe_nodes='0'
KUBE_REVAMPED_S_probe_pods='0'
KUBE_REVAMPED_S_popup_command='k9s'
KUBE_REVAMPED_S_popup_width='80%'
KUBE_REVAMPED_S_popup_height='80%'
KUBE_REVAMPED_S_value=''
KUBE_REVAMPED_S_value_ts=''
KUBE_REVAMPED_S_value_lock=''
KUBE_REVAMPED_S_value_lock_ts=''
KUBE_REVAMPED_S_dangling=''
KUBE_REVAMPED_S_cluster=''
KUBE_REVAMPED_S_user=''
KUBE_REVAMPED_S_reach=''
KUBE_REVAMPED_S_nodes=''
KUBE_REVAMPED_S_pods=''
KUBE_REVAMPED_DEFAULT_MENU_KEY='M-k'
KUBE_REVAMPED_DEFAULT_INTERVAL=10
KUBE_REVAMPED_RESET='#[default]'
KUBE_REVAMPED_UP='#[fg=green]'
KUBE_REVAMPED_DOWN='#[fg=red]'
KUBE_REVAMPED_PROBE_LIMIT=5
KUBE_REVAMPED_NOTES_SINCE=3.1
KUBE_REVAMPED_POPUP_SINCE=3.2
KUBE_REVAMPED_EMPTY='kube-revamped-empty-argument'
KUBE_REVAMPED_TMUX=''
KUBE_REVAMPED_NOTES=0
KUBE_REVAMPED_TOOL=''
KUBE_REVAMPED_JOB=''
KUBE_REVAMPED_KEYS=''
KUBE_REVAMPED_BOUND=''
KUBE_REVAMPED_SKIPPED=''
KUBE_REVAMPED_PLAN=''
KUBE_REVAMPED_NOW=0
KUBE_REVAMPED_CONTEXT=''
KUBE_REVAMPED_NAMESPACE=''
KUBE_REVAMPED_FOUND=''
KUBE_REVAMPED_CLUSTER=''
KUBE_REVAMPED_USER=''
KUBE_REVAMPED_SEGMENT=''
KUBE_REVAMPED_HEALTH=''
KUBE_REVAMPED_STORED=0
KUBE_REVAMPED_MENU_ITEMS=0
KUBE_REVAMPED_DOUBLED=''
KUBE_REVAMPED_COLOUR=''
KUBE_REVAMPED_LIMIT=10
KUBE_REVAMPED_TAB='	'
REVAMPED_CACHE_PREFIX=kube_revamped
REVAMPED_LOG_NS=kube-revamped
