function __fish_nft_needs_command
	set cmd (commandline -opc)
set -l skip_next 1
set -q cmd[2]; or return 0
for c in $cmd[2..-1]
test $skip_next -eq 0
and set skip_next 1
and continue
switch $c 
case "-h" "--help" "-v" "--version" "-f" "--filename" "-i" "--interactive"
return 1
case "-n" "--numeric" "-N" "--reversedns" "-s" "--stateless" "-c" "--check" "-a" "--handle" "-e" "--echo"
continue
case "*"
echo $c
return 1
end
end
end
