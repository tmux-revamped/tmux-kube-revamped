Source common.tape
Output hero.gif
Hide
Type "tmux -L revamped-screens attach -t demo"
Enter
Sleep 1.5s
Show
Sleep 2500ms
Screenshot context.png
Sleep 800ms
Hide
Ctrl+]
Type@5ms "prefix M-k, Down, Enter"
Enter
Show
Ctrl+B
Escape
Type@1ms "k"
Sleep 2s
Screenshot context-menu.png
Sleep 1s
Down
Sleep 600ms
Enter
Sleep 3500ms
Screenshot production.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "prefix M-n, Down, Enter"
Enter
Show
Ctrl+B
Escape
Type@1ms "n"
Sleep 2s
Screenshot namespace-menu.png
Sleep 1s
Down
Sleep 600ms
Enter
Sleep 3500ms
Screenshot namespace.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "tmux set -g @kube_revamped_show_cluster 1"
Enter
Show
Sleep 800ms
Type "tmux set -g @kube_revamped_show_cluster 1"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Type@5ms "tmux set -g @kube_revamped_probe_reach 1"
Enter
Show
Sleep 800ms
Type "tmux set -g @kube_revamped_probe_reach 1"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Type@5ms "tmux set -g @kube_revamped_probe_nodes 1"
Enter
Show
Sleep 800ms
Type "tmux set -g @kube_revamped_probe_nodes 1"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Type@5ms "tmux set -g @kube_revamped_probe_pods 1"
Enter
Show
Sleep 800ms
Type "tmux set -g @kube_revamped_probe_pods 1"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 5s
Screenshot probes.png
Sleep 1s
Hide
Ctrl+]
Type@5ms "prefix M-p, Enter"
Enter
Show
Ctrl+B
Escape
Type@1ms "p"
Sleep 2500ms
Screenshot popup.png
Sleep 1s
Enter
Sleep 1500ms
Hide
Ctrl+]
Type@5ms "tmux set -g @kube_revamped_popup_command lens"
Enter
Show
Sleep 800ms
Type "tmux set -g @kube_revamped_popup_command lens"
Hide
Ctrl+]
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Type@5ms "prefix M-p"
Enter
Show
Ctrl+B
Escape
Type@1ms "p"
Sleep 2500ms
Screenshot message.png
Sleep 1500ms
