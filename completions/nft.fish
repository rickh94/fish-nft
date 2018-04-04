# Completions for nft command line interface to nftables

function __fish_nft_needs_command
    set cmd (commandline -opc)
    set -l skip_next 1
    set -q cmd[2]
    or return 0
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

complete -c nft -f
complete -c nft -s h -l help -x -d "Show help message and all options"
complete -c nft -s v -l version -x -d "Show version"
complete -c nft -s n -l numeric -d "Show data numerically"
complete -c nft -s N -l reversedns -d "Translate IP addresses to names. Usually requires network traffic for DNS lookup."
complete -c nft -s s -l stateless -d "Omit stateful information of rules and stateful objects."
complete -c nft -s c -l check -d "Check commands validity without actually applying the changes."
complete -c nft -s a -l handle -d "Show rule hanldes in output"
complete -c nft -s e -l echo -d "When inserting items into the ruleset, print notifications."
complete -c nft -s I -l includepath -r -d "Add directory to the list of directories to be searched for included files."
complete -c nft -s f -l file -r -d "Read input from a file"
complete -c nft -s i -l interactive -x -d "Read input from an interactive readline CLI"
complete -c nft -n "__fish_nft_needs_command" -a add -d "Add a table, chain, rule, set, map, or object"
complete -c nft -n "__fish_nft_needs_command" -a list -d "List a ruleset, table, chain, set, map, or object"
complete -c nft -n "__fish_nft_needs_command" -a flush -d "Flush (delete everything from) a ruleset, table, chain, set, or map"
complete -c nft -n "__fish_nft_needs_command" -a export -d "Print the ruleset in a machine readable format (json or xml)"
complete -c nft -n "__fish_nft_needs_command" -a delete -d "Delete a table, chain, rule, set, element, map, or object."
complete -c nft -n "__fish_nft_needs_command" -a create -d "Similar to add but returns an error for existing chain."
complete -c nft -n "__fish_nft_needs_command" -a rename -d "Rename the specified chain"
complete -c nft -n "__fish_nft_needs_command" -a insert -d "Similar to the add command, but the rule is prepended to the beginning of the chain or before the rule at the given position."
complete -c nft -n "__fish_nft_needs_command" -a replace -d "Similar to the add command, but replaces the specified rule."
complete -c nft -n "__fish_nft_needs_command" -a reset -d "List-and-reset stateful object."
complete -c nft -n "__fish_nft_needs_command" -a chain -d "Edit an existing chain."
