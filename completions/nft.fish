# Completions for nft command line interface to nftables
# Based heavily on the built in git completion in fish shell
#

set -gu __nft_choices "chain" "table" "rule" "set" "element" "map"
set -gu __nft_families "ip" "ip6" "inet" "arp" "bridge" "netdev"
set -gu __nft_rule_matches "ip" "ip6" "tcp" "udp" "udplite" "sctp" "dccp" "ah" "esp" "comp" \
"icmp" "icmpv6" "ether" "dst" "frag" "hbh" "mh" "rt" "vlan" "arp" "ct" "meta"

# check if nft is waiting for a command
function __nft_needs_command
    set -l cmd (commandline -opc)
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

# check what command nft is using
function __nft_using_command
  set -l cmd (__nft_needs_command)
  test -z "$cmd"
  and return 1
  contains -- $cmd $argv
  and return 0
end


# check whether nft is has a chain/table/rule choice
function __nft_has_choice
  set -l cmd (commandline -opc)
  for word in $__nft_choices
    if contains -- $word $cmd
      return 0
    end
  end
  return 1
end

# check whether chain/table/rule/etc is needed
function __nft_needs_choice
  set -l cmd (commandline -opc)
  if __nft_has_choice
    return 1
  end
  return (__nft_using_command $argv)
end


# check whether a family is needed
function __nft_needs_family
  set -l cmd (commandline -opc)
  contains -- $cmd[-1] $__nft_choices
  and return 0
  return 1
end

# check whether a table is needed
function __nft_needs_table
  set -l cmd (commandline -opc)
  # if command is long, we are beyond table names. Fixes some overlaps between
  # families and rule matches.
  set -l max_length 4
  if contains -- sudo $cmd
    set max_length (math $max_length+1)
  end
  if test (count $cmd) -gt $max_length
    or __nft_using_command describe
    return 1
  end
  # if we just had a choice or family, we probably need a table
  contains -- $cmd[-1] $__nft_choices $__nft_familes
  and return 0
  return 1
end

# check whether nft needs chain
function __nft_needs_chain
  set -l cmd (commandline -opc)
  if not contains -- chain $cmd; and not contains -- rule $cmd
    return 1
  end
  # what will be in the command line is unknown, but it must be at minimum:
  # "nft <command> <chain/rule> <table>" which is 4 words long. This will
  # determine whether it needs a chain
  set -l min_len 4
  if contains -- sudo $cmd
    set min_len (math $min_len+1)
  end
  # If it has a family (optional argument) it will be one longer
  for word in $__nft_families
    if contains -- $word $cmd
      set min_len (math $min_len+1)
    end
  end
  if test (count $cmd) -eq $min_len
    return 0
  end
  return 1
end


# check whether nft needs rule suggestions
function __nft_needs_rule_match
  set -l cmd (commandline -opc)
  # need to be using add rule
  if not __nft_using_command "add"
    or not contains -- "rule" $cmd
    return 1
  end
  # using length to determine where we are in rule construction
  set -l min_len 5
  if contains -- sudo $cmd
    set min_len (math $min_len+1)
  end
  # If it has a family (optional argument) it will be one longer
  for word in $__nft_families
    if contains -- $word $cmd
      set min_len (math $min_len+1)
    end
  end
  if test (count $cmd) -lt $min_len
    return 1
  end
  # after a match, you have some kind of option, then an argument (i.e. ip daddr 1.2.3.4)
  # so only match if the previous match is not in the last two arguments.
  for word in $cmd[-2..-1]
    contains -- $word $__nft_rule_matches
    and return 1
  end
  # contrack sometimes requires more arguments
  if contains -- "ct" $cmd[-3..-1]
    contains -- "original" $cmd[-2..-1]
    and return 1
    contains -- "reply" $cmd[-2..-1]
    and return 1
  end
  return 0
end


# check whether a certain rule match is in use, and figuring
# out whether an argument for that is needed
function __nft_using_rule_match
  set -l cmd (commandline -opc)
  contains -- $cmd[-1] $argv
  or return 1
  __nft_using_command describe
  and return 0
  if contains -- $argv $__nft_families
    if test (count $cmd) -lt 6
      return 1
    end
  end
  return 0
end

function __nft_using_ct_original_reply
  set -l cmd (commandline -opc)
  set -q cmd[-2]
  or return 1
  if not [ $cmd[-2] = "ct" ]
    return 1
  end
  contains -- $cmd[-1] "original" "reply"
  or return 1
  return 0
end

function __nft_describing_command
  set -l cmd (commandline -opc)
  for word in $cmd
    contains -- $word $__nft_rule_matches
    and return 1
  end
  not __nft_using_command describe
  and return 1
  return 0
end

# nft must take a subcommand or a switch, file completions are useless here
complete -c nft -f

# Switches
complete -c nft -s h -l help -x -d "Show help message and all options"
complete -c nft -s v -l version -x -d "Show version"
complete -c nft -s n -l numeric -d "Show data numerically"
complete -c nft -s N -l reversedns -d "Translate IP addresses to names. Usually requires network traffic for DNS lookup."
complete -c nft -s s -l stateless -d "Omit stateful information of rules and stateful objects."
complete -c nft -s c -l check -d "Check commands validity without actually applying the changes."
complete -c nft -s a -l handle -d "Show rule hanldes in output"
complete -c nft -s e -l echo -d "When inserting items into the ruleset, print notifications. (not in older versions)"
complete -c nft -s I -l includepath -r -d "Add directory to the list of directories to be searched for included files."
complete -c nft -s f -l file -r -d "Read input from a file"
complete -c nft -s i -l interactive -x -d "Read input from an interactive readline CLI"

# Subcommands
complete -c nft -n "__nft_needs_command" -a add      -d "Add a table, chain, rule, set, map, or object"
complete -c nft -n "__nft_needs_command" -a list     -d "List a ruleset, table, chain, set, map, or object"
complete -c nft -n "__nft_needs_command" -a flush    -d "Flush (delete everything from) a ruleset, table, chain, set, or map"
complete -c nft -n "__nft_needs_command" -a export   -d "Print the ruleset in a machine readable format (json or xml)"
complete -c nft -n "__nft_needs_command" -a delete   -d "Delete a table, chain, rule, set, element, map, or object."
complete -c nft -n "__nft_needs_command" -a create   -d "Similar to add but returns an error for existing chain."
complete -c nft -n "__nft_needs_command" -a rename   -d "Rename the specified chain"
complete -c nft -n "__nft_needs_command" -a insert   -d "Similar to the add command, but the rule is prepended to the beginning of the chain or before the rule at the given position."
complete -c nft -n "__nft_needs_command" -a replace  -d "Similar to the add command, but replaces the specified rule."
complete -c nft -n "__nft_needs_command" -a reset    -d "List-and-reset stateful object."
complete -c nft -n "__nft_needs_command" -a chain    -d "Edit an existing chain."
complete -c nft -n "__nft_needs_command" -a describe -d "Show information about the type of an expression and its data type"

# command groups(ish). table/chain/rule/etc
complete -c nft -n "__nft_needs_choice add delete"     -a "table chain set rule map element"
complete -c nft -n "__nft_needs_choice list"           -a "ruleset tables chains sets maps table chain set map"
complete -c nft -n "__nft_needs_choice flush"          -a "ruleset table chain set map"
complete -c nft -n "__nft_needs_choice export"         -a "ruleset"
complete -c nft -n "__nft_needs_choice create rename"  -a "chain"
complete -c nft -n "__nft_needs_choice insert replace" -a "rule"
complete -c nft -n "__nft_describing_command" -a "$__nft_rule_matches"

# after command groups
complete -c nft -n "__nft_needs_family"                                 -a "$__nft_families"                                     -d "family (optional)"
complete -c nft -n "__nft_needs_table"                                  -a "filter nat raw mangle security"                      -d "common table name"
complete -c nft -n "__nft_needs_chain"                                  -a "input output prerouting postrouting tcp udp forward" -d "common chain name"
complete -c nft -n "__nft_needs_rule_match"                             -a "$__nft_rule_matches"                                 -d "rule match"
complete -c nft -n "__nft_using_rule_match ip ip6"                      -a "dscp"                                                -d "differentiated services code point"
complete -c nft -n "__nft_using_rule_match ip ip6 udp meta"             -a "length"                                              -d "total packet length in bytes"
complete -c nft -n "__nft_using_rule_match ip"                          -a "id"                                                  -d "IP ID"
complete -c nft -n "__nft_using_rule_match icmp icmpv6"                 -a "id"                                                  -d "ICMP(v6) packet id"
complete -c nft -n "__nft_using_rule_match frag"                        -a "id"
complete -c nft -n "__nft_using_rule_match ip frag"                     -a "frag-off"                                            -d "Fragmentation offset"
complete -c nft -n "__nft_using_rule_match ip"                          -a "ttl"                                                 -d "Time to live"
complete -c nft -n "__nft_using_rule_match ip"                          -a "protocol"                                            -d "Upper layer protocol"
complete -c nft -n "__nft_using_rule_match meta"                        -a "protocol"                                            -d "ethertype protocol"
complete -c nft -n "__nft_using_rule_match ip meta tcp"                 -a "checksum"                                            -d "IP header checksum"
complete -c nft -n "__nft_using_rule_match udp"                         -a "checksum"                                            -d "UDP checksum"
complete -c nft -n "__nft_using_rule_match udplite"                     -a "checksum"                                            -d "udplite checksum"
complete -c nft -n "__nft_using_rule_match sctp"                        -a "checksum"                                            -d "sctp checksum"
complete -c nft -n "__nft_using_rule_match icmp icmpv6"                 -a "checksum"                                            -d "ICMP(v6) packet checksum"
complete -c nft -n "__nft_using_rule_match mh"                          -a "checksum"
complete -c nft -n "__nft_using_rule_match ip ip6 ether"                -a "saddr"                                               -d "Source address"
complete -c nft -n "__nft_using_rule_match ip ip6"                      -a "daddr"                                               -d "Destination address"
complete -c nft -n "__nft_using_rule_match ip ip6"                      -a "version"                                             -d "IP header version"
complete -c nft -n "__nft_using_rule_match ip ah dst hbh mh rt"         -a "hdrlength"                                           -d "Header length"
complete -c nft -n "__nft_using_rule_match ip6"                         -a "flowlabel"                                           -d "Flow label"
complete -c nft -n "__nft_using_rule_match ip6 comp dst frag hbh mh rt" -a "nexthdr"                                             -d "Next header type"
complete -c nft -n "__nft_using_rule_match ip6"                         -a "hoplimit"                                            -d "Hop limit"
complete -c nft -n "__nft_using_rule_match tcp udp udplite sctp dccp"   -a "dport"                                               -d "Destination port"
complete -c nft -n "__nft_using_rule_match tcp udp udplite sctp dccp"   -a "sport"                                               -d "Source port"
complete -c nft -n "__nft_using_rule_match tcp ah esp"                  -a "sequence"                                            -d "Sequence number"
complete -c nft -n "__nft_using_rule_match icmp icmpv6"                 -a "sequence"                                            -d "ICMP(v6) packet sequence"
complete -c nft -n "__nft_using_rule_match tcp"                         -a "ackseq"                                              -d "Acknowledgement number"
complete -c nft -n "__nft_using_rule_match tcp comp"                    -a "flags"
complete -c nft -n "__nft_using_rule_match tcp"                         -a "window"
complete -c nft -n "__nft_using_rule_match tcp"                         -a "urgptr"                                              -d "Urgent pointer"
complete -c nft -n "__nft_using_rule_match tcp"                         -a "doff"                                                -d "Data offset"
complete -c nft -n "__nft_using_rule_match sctp"                        -a "vtag"                                                -d "Verification tag"
complete -c nft -n "__nft_using_rule_match dccp"                        -a "type"                                                -d "Type of packet"
complete -c nft -n "__nft_using_rule_match icmp icmpv6"                 -a "type"                                                -d "ICMP(v6) packet type"
complete -c nft -n "__nft_using_rule_match ether mh rt"                 -a "type"
complete -c nft -n "__nft_using_rule_match ah frag mh"                  -a "reserved"
complete -c nft -n "__nft_using_rule_match ah esp"                      -a "spi"
complete -c nft -n "__nft_using_rule_match comp"                        -a "cpi"                                                 -d "Compression Parameter Index"
complete -c nft -n "__nft_using_rule_match icmp icmpv6"                 -a "code"                                                -d "ICMP(v6) packet code"
complete -c nft -n "__nft_using_rule_match icmp icmpv6"                 -a "mtu"                                                 -a "ICMP(v6) packet mtu"
complete -c nft -n "__nft_using_rule_match icmp"                        -a "gateway"                                             -a "ICMP packet gateway"
complete -c nft -n "__nft_using_rule_match icmpv6"                      -a "max-delay"                                           -a "ICMPv6 packet max delay"
complete -c nft -n "__nft_using_rule_match frag"                        -a "more-fragments"
complete -c nft -n "__nft_using_rule_match rt"                          -a "seg-left"
complete -c nft -n "__nft_using_rule_match vlan"                        -a "cfi pcp"
complete -c nft -n "__nft_using_rule_match arp"                         -a "ptype"                                               -d "Payload type"
complete -c nft -n "__nft_using_rule_match arp"                         -a "htype"                                               -d "Header type"
complete -c nft -n "__nft_using_rule_match arp"                         -a "hlen"                                                -d "Header length"
complete -c nft -n "__nft_using_rule_match arp"                         -a "plen"                                                -d "Payload length"
complete -c nft -n "__nft_using_rule_match arp"                         -a "operation"
complete -c nft -n "__nft_using_rule_match ct"                          -a "state"                                               -d "State of the connection"
complete -c nft -n "__nft_using_rule_match ct"                          -a "direction"                                           -d "Direction of the packet relative to the connection"
complete -c nft -n "__nft_using_rule_match ct"                          -a "status"                                              -d "Status of the connection"
complete -c nft -n "__nft_using_rule_match ct"                          -a "mark"                                                -d "Mark of the connection"
complete -c nft -n "__nft_using_rule_match ct"                          -a "expiration"                                          -d "Connection expiration type"
complete -c nft -n "__nft_using_rule_match ct"                          -a "helper"                                              -d "Helper associated with the connection"
complete -c nft -n "__nft_using_rule_match meta"                        -a "iifname"                                             -d "Input interface name"
complete -c nft -n "__nft_using_rule_match meta"                        -a "oifname"                                             -d "Output interface name"
complete -c nft -n "__nft_using_rule_match meta"                        -a "iif"                                                 -d "Input interface index"
complete -c nft -n "__nft_using_rule_match meta"                        -a "oif"                                                 -d "Output interface index"
complete -c nft -n "__nft_using_rule_match meta"                        -a "iiftype"                                             -d "Input interface type"
complete -c nft -n "__nft_using_rule_match meta"                        -a "oiftype"                                             -d "Output interface type"
complete -c nft -n "__nft_using_rule_match meta"                        -a "nfproto l4proto cgroup"
complete -c nft -n "__nft_using_rule_match meta"                        -a "mark"                                                -d "Packet mark"
complete -c nft -n "__nft_using_rule_match meta"                        -a "skuid"                                               -d "UID associated with originating socket"
complete -c nft -n "__nft_using_rule_match meta"                        -a "skgid"                                               -d "GID associated with originating socket"
complete -c nft -n "__nft_using_rule_match meta"                        -a "rtclassid"                                           -d "Routing realm"
complete -c nft -n "__nft_using_rule_match meta"                        -a "pkttype"                                             -d "Packet type"
complete -c nft -n "__nft_using_rule_match meta"                        -a "cpu"                                                 -d "CPU ID"
complete -c nft -n "__nft_using_rule_match meta"                        -a "iffgroup"                                            -d "Input interface group"
complete -c nft -n "__nft_using_rule_match meta"                        -a "oifgroup"                                            -d "Output interface group"


# some special stuff for conntrack
complete -c nft -n "__nft_using_rule_match ct"                          -a "original reply"
complete -c nft -n "__nft_using_ct_original_reply"                      -a "bytes packets saddr daddr l3proto protocol proto-dst proto-src"
