#!/usr/bin/env python3

import json
import re
import sys

def to_result_sarif(path, line, code, severity, message):
    return {
        "level": severity,
        "locations": [
            {
                "physicalLocation": {
                    "artifactLocation": {
                        "uri": path,
                    },
                    "region": {
                        "startColumn": 0,
                        "startLine": int(line),
                    },
                }
            }
        ],
        "message": {
            "text": message,
        },
        "ruleId": "SyntaxError",
    }

def main(argv):
    if len(argv) < 2:
        print("Usage: parse_gdscript_formatter_to_sarif.py <exit_code>")
        sys.exit(1)

    results = []

    for line in sys.stdin:
        line = line.strip()
        m = re.match(r"((?P<path>[^:]+):(?P<line>\d+):(?P<code>[^:]+):(?P<severity>[^:]+):\s*(?P<message>.*))", line)
        if not m:
            print(f"Unexpected output from gdscript-formatter: {line}", file=sys.stderr)
            sys.exit(int(argv[1]))

        results.append(to_result_sarif(m.group("path"), m.group("line"), m.group("code"), m.group("severity"), m.group("message")))

    sarif = {
        "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
        "version": "2.1.0",
        "runs": [{"results": results}],
    }

    print(json.dumps(sarif, indent=2))

if __name__ == "__main__":
    main(sys.argv)
