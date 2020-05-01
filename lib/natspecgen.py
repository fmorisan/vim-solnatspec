#!/usr/bin/env python3

import json
import argparse
import subprocess

ap = argparse.ArgumentParser("natgenspec.py")
ap.add_argument("file", help="File to parse with solc.")
ap.add_argument("symbol", help="Symbol to generate natspec docs for.")

args = ap.parse_args()
solc_out = subprocess.check_output(['solc', '--ast-json', args.file]).decode('utf8')
solc_split = solc_out.split('\n')

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

def dfs(node):
    node_attributes = node.get('attributes')
    if node_attributes.get('name') == args.symbol:
        return node
    else:
        children = node.get('children')
        if not children:
            return None
        else:
            for child in children:
                success = dfs(child)
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


symbol_node = dfs(ast_json)
params = look_for_parameters(symbol_node)
print(f"/// @notice")
print(f"/// @dev")
for param in params:
    print(f"/// @param {param['attributes']['type']} {param['attributes']['name']}")
