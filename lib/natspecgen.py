#!/usr/bin/env python3

import sys
import json
import argparse
import subprocess

ap = argparse.ArgumentParser("natgenspec.py")
ap.add_argument("file", help="File to parse with solc.")
ap.add_argument("line", help="Line number of definition", type=int)
ap.add_argument("-i", "--indent", default=0, help="Indentation level in space count.", type=int)

args = ap.parse_args()

solc_out = subprocess.check_output(['solc', '--ast-json', args.file]).decode('utf8')
solc_split = solc_out.split('\n')

author_name = subprocess.check_output([
    'git',
    'config',
    'user.name'
]).decode('utf8').strip()
author_email = subprocess.check_output([
    'git',
    'config',
    'user.email'
]).decode('utf8').strip()

linebreak_byte_numbers = []
with open(args.file, 'r') as f:
    for i, b in enumerate(f.read()):
        if b == '\n':
            linebreak_byte_numbers.append(i)

start = None
end = None

for i, line in enumerate(solc_split):
    if start is not None:
        if '====' in line:
            end = i
            break
    if '====' in line and args.file in line:
        start = i

ast_json = json.loads(
    "\n".join(solc_split[start+1:end])
)

def line_dfs(node):
    node_attributes = node.get('attributes', {})
    # solc AST doesnt give us line numbers LMAO
    byte_pos = int(node.get('src').split(':')[0])
    # hacker moment
    line_nr = min(line for (line, byte) in enumerate(linebreak_byte_numbers) if byte >= byte_pos)
    if line_nr == args.line and node.get('name') in ['ContractDefinition', 'FunctionDefinition']:
        return node
    else:
        children = node.get('children')
        if not children:
            return None
        else:
            for child in children:
                success = line_dfs(child)
                if success:
                    return success


def look_for_parameters(function_node):
    parameter_list_node = list(
        filter(
            lambda x: x.get('name') == "ParameterList",
            function_node.get('children')
        )
    )[0]
    return parameter_list_node.get('children')


def print_indented(string):
    print(' '*int(args.indent) + string)

if args.line:
    symbol_node = line_dfs(ast_json)
else:
    symbol_node = dfs(ast_json)


if not symbol_node:
    sys.exit(1)

if symbol_node.get('name') == "ContractDefinition":
    print_indented(
        f"/// @author {author_name} ({author_email})"
    )
    print_indented(
        f"/// @title {symbol_node['attributes']['name']}"
    )
print_indented(f"/// @notice")
print_indented(f"/// @dev")
if symbol_node.get('name') == "FunctionDefinition":
    params = look_for_parameters(symbol_node)
    for param in params:
        print_indented(f"/// @param {param['attributes']['name']} {param['attributes']['type']}")
