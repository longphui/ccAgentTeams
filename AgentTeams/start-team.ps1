$wt = "C:\Program Files\terminal-1.25.1171.0\wt.exe"
$dir = "D:\work\cc\AgentTeams"

$args = @(
    '-w', '0',
    '-d', $dir, '--title', 'Architect',
    'cmd', '/k', '_wt-architect.bat',
    ';',
    'split-pane', '-V', '-s', '0.5',
    '-d', $dir, '--title', 'Developer',
    'cmd', '/k', '_wt-developer.bat',
    ';',
    'move-focus', 'right',
    ';',
    'split-pane', '-H', '-s', '0.5',
    '-d', $dir, '--title', 'Reviewer',
    'cmd', '/k', '_wt-reviewer.bat',
    ';',
    'move-focus', 'up',
    ';',
    'split-pane', '-V', '-s', '0.5',
    '-d', $dir, '--title', 'Developer1',
    'cmd', '/k', '_wt-developer1.bat',
    ';',
    'move-focus', 'down',
    ';',
    'split-pane', '-V', '-s', '0.5',
    '-d', $dir, '--title', 'QA',
    'cmd', '/k', '_wt-qa.bat',
    ';',
    'move-focus', 'left'
)

& $wt @args
