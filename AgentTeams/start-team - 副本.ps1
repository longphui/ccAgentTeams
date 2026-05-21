$wt = "C:\Program Files\terminal-1.25.1171.0\wt.exe"
$dir = "D:\work\cc"

$args = @(
    '-w', '0',
    '-d', $dir, '--title', 'Architect',
    'powershell', '-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', 'claude --name Architect /agent-architect',
    ';',
    'split-pane', '-V', '-s', '0.5',
    '-d', $dir, '--title', 'Developer',
    'powershell', '-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', 'claude --name Developer /loop 1m /agent-trigger developer',
    ';',
    'move-focus', 'right',
    ';',
    'split-pane', '-H', '-s', '0.5',
    '-d', $dir, '--title', 'Reviewer',
    'powershell', '-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', 'claude --name Reviewer /loop 1m /agent-trigger reviewer',
    ';',
    'move-focus', 'up',
    ';',
    'split-pane', '-V', '-s', '0.5',
    '-d', $dir, '--title', 'Developer1',
    'powershell', '-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', 'claude --name Developer1 /loop 1m /agent-trigger developer1',
    ';',
    'move-focus', 'down',
    ';',
    'split-pane', '-V', '-s', '0.5',
    '-d', $dir, '--title', 'QA',
    'powershell', '-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', 'claude --name QA /loop 1m /agent-trigger qa',
    ';',
    'move-focus', 'left'
)

& $wt @args