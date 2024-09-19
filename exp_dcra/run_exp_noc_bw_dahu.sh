#!/bin/bash
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Error: Missing required parameters."
    exit 1
fi

if [ $1 -gt 8 ]; then
  apps="0 1 2 3 4 5"
else
  apps=$1
fi
# grid_w tile在一行或者一列上的个数
if [ -z "$4" ]; then
  let grid_w=64
  echo "Default grid_w=$grid_w"
else
  let grid_w=$4
  echo "grid_w=$grid_w"
fi

if [ -z "$5" ]; then
  echo "All datasets by default"
  datasets="Kron22 wikipedia"
else
  echo "Dataset $5"
  datasets="$5"
fi
# 测试的实验的上下界
let lb=$2
let ub=$3
run() {
    local i="$1"
    if [ $lb -le $i ] && [ $ub -ge $i ]; then
        echo "EXPERIMENT: $i"
        echo "ARGS: $options -d $datasets -a $apps"
        exp/run_dahu.sh $options -d "$datasets" -a "$apps"
    fi
}


# :'
# 这一段脚本定义了一个名为 `set` 的函数，用于修改文件 `src/configs/param_energy.h` 中某些参数的值。具体来说，这个函数使用 `sed` 工具来查找并替换文件中的某些变量的值。

# 以下是对这段代码的详细解释：

# ```bash
# set() {
#   sed -i "s/\(${var}\s*=\s*\)[^;]*/\1${value}/" "src/configs/param_energy.h"
# }
# ```

# ### 具体解释

# 1. **`set()`**：
#    - 定义一个名为 `set` 的函数。这个函数在调用时会执行其内部的命令。

# 2. **`sed`**：
#    - `sed` 是一个流编辑器，用于对文件中的文本进行查找、替换、删除和插入等操作。

# 3. **`-i`**：
#    - `-i` 参数表示对文件进行原地编辑（即直接修改文件，而不是输出到标准输出）。

# 4. **`"s/\(${var}\s*=\s*\)[^;]*/\1${value}/"`**：
#    - 这是 `sed` 的查找和替换模式。具体解释如下：
#      - **`s/.../.../`**：`s` 表示替换操作。
#      - **`\(${var}\s*=\s*\)`**：这是一个捕获组，用于匹配变量名和等号。具体来说：
#        - `${var}` 是在脚本中定义的变量名。
#        - `\s*` 表示零个或多个空白字符。
#        - `=` 是等号。
#      - **`[^;]*`**：匹配等号后面到分号之前的所有字符，即原来的数值或者字符串。
#      - **`\1${value}`**：`\1` 表示前面捕获组（即变量名和等号）的内容，`${value}` 是新的值。整个替换模式将原来的数值或字符串替换为新的值。

# 5. **`"src/configs/param_energy.h"`**：
#    - 指定目标文件为 `src/configs/param_energy.h`，这是要被编辑的文件路径。

# ### 示例

# 假设你有一个配置文件 `src/configs/param_energy.h`，其内容如下：

# ```c
# noc_freq = 1.0;
# some_other_param = 42;
# ```

# 调用函数 `set` 时，例如：

# ```bash
# var=noc_freq
# value=2.0
# set
# ```

# 这会将 `noc_freq` 的值从 `1.0` 修改为 `2.0`，结果文件内容如下：

# ```c
# noc_freq = 2.0;
# some_other_param = 42;
# ```

# ### 总结

# `set` 函数的主要目的是通过 `sed` 工具自动修改配置文件中的变量值，从而简化了手动编辑配置文件的过程。这在需要频繁更改配置的自动化流程中非常有用。

# '

set() {
  sed -i "s/\(${var}\s*=\s*\)[^;]*/\1${value}/" "src/configs/param_energy.h"
}

exp="NOC"
verbose=1
assert=0

let dcache=0

# Run mode
let local_run=2
let chiplet_w=16 # So that the NoC is more the bottleneck than the memory
let th=16

prefix="-v $verbose -r $assert -y $dcache -s $local_run -c $chiplet_w"

let noc_conf=0
let torus=0

#"0--Mesh"
options="-n ${exp}0 -t $th $prefix -m $grid_w -u $noc_conf -o $torus -l 0"
run 0

#"1--Mesh_wide"
let noc_conf=1
options="-n ${exp}1 -t $th $prefix -m $grid_w -u $noc_conf -o $torus -l 0"
run 1

#"2--Torus_wide"
let torus=1
options="-n ${exp}2 -t $th $prefix  -m $grid_w -u $noc_conf -o $torus -l 0"
run 2

#"3--Torus_wide + inter-die"-skip (ruche is inter-die when not defined)
options="-n ${exp}3 -t $th $prefix  -m $grid_w -u $noc_conf -o $torus"
run 3

#"4--Torus 2x"
#这里是把noc的频率设置成两倍
var=noc_freq; value=2.0; set
options="-n ${exp}4 -t $th $prefix  -m $grid_w -u $noc_conf -o $torus"
run 4


var=noc_freq; value=1.0; set