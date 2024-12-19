import * as FS from "fs";
import * as Path from "path";

class FileUtils {
  public async checkFileExists(path: string): Promise<boolean> {
    if (path === "./") {
      return true;
    } else {
      return new Promise((resolve) => {
        FS.access(path, (error) => {
          if (error !== null) {
            resolve(false);
          } else {
            FS.readdir(Path.dirname(path), (error2, names) => {
              if (error2 !== null) {
                resolve(false);
              } else {
                resolve(names.includes(Path.basename(path)));
              }
            });
          }
        });
      });
    }
  }

  public async readBuffer(path: string): Promise<Buffer> {
    if (await this.checkFileExists(path) !== true) {
      throw new Error(`${path} Not Exists`);
    } else {
      return new Promise<Buffer>((resolve, reject) => {
        FS.stat(path, (error, stat) => {
          if (error !== null) {
            reject(error);
          } else if (stat.isDirectory() === true) {
            reject(new Error(`${path} Is Folder`));
          } else {
            FS.readFile(path, (error2, buffer) => {
              if (error2 !== null) {
                reject(error2);
              } else {
                resolve(buffer);
              }
            });
          }
        });
      });
    }
  }

  public async readText(path: string): Promise<string> {
    return (await this.readBuffer(path)).toString();
  }

  public async getFileInfo(path: string): Promise<{
    size: number;
    createTime: Date;
    lastUpdateTime: Date;
  }> {
    if (await this.checkFileExists(path) !== true) {
      throw new Error(`${path} Not Exists`);
    } else {
      return new Promise((resolve, reject) => {
        FS.stat(path, (error, stat) => {
          if (error !== null) {
            reject(error);
          } else {
            resolve({
              size: stat.isDirectory() === true ? 0 : stat.size,
              createTime: stat.birthtime,
              lastUpdateTime: stat.mtime,
            });
          }
        });
      });
    }
  }

  public async deleteFile(path: string) {
    if (await this.checkFileExists(path) === true) {
      return new Promise<void>((resolve, reject) => {
        FS.unlink(path, (error) => {
          if (error !== null) {
            reject(error);
          } else {
            resolve();
          }
        });
      });
    }
  }

  public async createFolder(path: string): Promise<void> {
    if (await this.checkFileExists(path) !== true) {
      const folderPath = Path.dirname(path);
      if (folderPath !== path && folderPath + "/" !== path) {
        if (
          folderPath === "." || await this.checkFileExists(folderPath) === true
        ) {
          return new Promise((resolve, reject) => {
            FS.mkdir(path, (error) => {
              if (error !== null) {
                reject(error);
              } else {
                resolve();
              }
            });
          });
        } else {
          await this.createFolder(folderPath);
          return this.createFolder(path);
        }
      }
    }
  }

  public async write(path: string, content: Buffer | string) {
    await this.createFolder(Path.dirname(path));
    return new Promise<void>((resolve, reject) => {
      FS.writeFile(path, content, (error) => {
        if (error !== null) {
          reject(error);
        } else {
          resolve();
        }
      });
    });
  }

  public async getAllFiles(path: string): Promise<string[]> {
    const files: string[] = [];

    if (await this.checkFileExists(path) !== true) {
      throw new Error(`${path} Not Exists`);
    } else {
      return new Promise((resolve, reject) => {
        FS.readdir(path, { withFileTypes: true }, (error, dirEntries) => {
          if (error !== null) {
            reject(error);
          } else {
            const promises: Promise<void>[] = [];
            for (const dirEntry of dirEntries) {
              const fullPath = Path.join(path, dirEntry.name);
              if (dirEntry.isDirectory()) {
                const promise = this.getAllFiles(fullPath)
                  .then((subFiles) => {
                    files.push(...subFiles);
                  });
                promises.push(promise);
              } else if (dirEntry.isFile()) {
                files.push(fullPath);
              }
            }
            Promise.all(promises)
              .then(() => resolve(files))
              .catch(reject);
          }
        });
      });
    }
  }
}

export default new FileUtils();
