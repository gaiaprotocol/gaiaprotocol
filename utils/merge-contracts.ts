import FileUtils from "./FileUtils.js";

let fullSource = "";

const files = await FileUtils.getAllFiles("../contracts");
for (const file of files) {
  if (file.endsWith(".sol")) {
    fullSource += await FileUtils.readText(file) + "\n";
  }
}

fullSource = fullSource
  .split("\n")
  .filter((line) => !line.startsWith('import ".'))
  .join("\n");

fullSource = fullSource
  .split("\n")
  .filter((line) =>
    line.trim() !== "// SPDX-License-Identifier: MIT" &&
    !line.trim().startsWith("pragma solidity")
  )
  .join("\n");

fullSource = `// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.28;

  ${fullSource}`;

await FileUtils.write("../full/full.sol", fullSource);
