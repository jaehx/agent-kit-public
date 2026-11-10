#!/usr/bin/env bash
# prompt-polish: checks every paragraph in hooks/models/*.md against Anthropic's live prompting guides.
# A paragraph passes in one of two ways:
#   verbatim · its text appears word for word in one of the guides (curly quotes and line breaks aside)
#   adapted  · it opens with a line `<!-- adapted: <section> -->` and that section is a heading in one of the guides.
#              Use this for guide advice restated as a rule, where the guide gives no prompt text to copy.
# Anything else fails: text with no guide behind it does not belong in a model rules file.
# The guides fetched are the ones the files are named after (hooks/models/opus-5-5.md → prompting-claude-opus-5-5.md);
# a paragraph may come from any of them, since a guide can name an earlier one as its starting point.
# Needs curl and perl, and network access. Exit 0 pass, 1 a paragraph failed, 2 a guide could not be fetched.
# Run before a release and whenever a guide may have changed: bash tests/guide-verbatim.sh
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

for f in "$ROOT"/hooks/models/*.md; do
  name="$(basename "$f" .md)"
  code="$(curl -sL -m 30 -o "$TMP/$name.guide" -w '%{http_code}' "$BASE-$name.md")"
  if [ "$code" != 200 ] || ! grep -q '^## ' "$TMP/$name.guide"; then
    echo "could not fetch the guide for $name (HTTP $code): $BASE-$name.md"; exit 2
  fi
done

perl -e '
  use strict; use warnings;
  my ($tmp, @files) = @ARGV;
  sub norm { my $s = shift; $s =~ s/\r//g; $s =~ s/\xE2\x80[\x98\x99]/\x27/g; $s =~ s/\xE2\x80[\x9C\x9D]/"/g; $s =~ s/\s+/ /g; $s =~ s/^ | $//g; $s }
  sub slurp { open my $h, "<", shift or die $!; local $/; <$h> }
  my (%guide, %heads);
  for my $g (glob "$tmp/*.guide") {
    (my $n = $g) =~ s{.*/|\.guide$}{}g;
    my $raw = slurp($g);
    $guide{$n} = norm($raw);
    $heads{$n} = { map { norm($_) => 1 } $raw =~ /^#{2,3} +(.+)$/mg };
  }
  my $bad = 0;
  for my $f (@files) {
    (my $n = $f) =~ s{.*/|\.md$}{}g;
    print "== $n\n";
    my $text = slurp($f); $text =~ s/\r//g;
    for my $p (split /\n{2,}/, $text) {
      next if $p =~ /^\s*$/ || $p =~ /^# / || $p =~ /^Source:/;
      my $section = $p =~ s/^<!-- adapted: (.+?) -->\n// ? $1 : "";
      my $body = norm($p);
      my $shown = substr($body, 0, 60);
      my @in = grep { index($guide{$_}, $body) >= 0 } sort keys %guide;
      if (@in)            { print "  verbatim (@in)  $shown...\n" }
      elsif ($section) {
        my @sec = grep { $heads{$_}{norm($section)} } sort keys %heads;
        if (@sec) { print "  adapted from \"$section\" (@sec)  $shown...\n" }
        else      { print "  FAIL: no guide has a section \"$section\"  $shown...\n"; $bad = 1 }
      }
      else { print "  FAIL: not in any guide and not marked adapted  $shown...\n"; $bad = 1 }
    }
  }
  exit $bad;
' "$TMP" "$ROOT"/hooks/models/*.md
