# 自動化 MAILDSrv 憑證驗證、比對與部署工具（PowerShell 4.0 相容）
本專案提供一套完整的 Raiden MailD 憑證自動更新流程，包含：

* 憑證有效性檢查（含鏈結、撤銷、到期日）
* CN 比對、Thumbprint 比對、NotAfter 比對
* 自動備份舊憑證
* 自動部署新憑證
* 自動重啟 Raiden MailD 服務
* 完整 Log 記錄
* 完全相容 PowerShell 4.0 / Windows Server 2012 R2

此專案搭配 [WIN-ACME](https://www.win-acme.com/) 自動化憑證來源的環境。

## 專案結構
```
Deploy-Cert4MAILDSrv_PS1_MSAI/
│
├── Validate-CerCertificate.ps1      # 憑證有效性檢查（鏈結、撤銷、到期）
├── Compare-CerCertificates.ps1      # 比對新舊憑證（CN、Thumbprint、NotAfter）
├── Deploy-Certificate.ps1           # 部署流程（備份、覆蓋、Log）
├── Restart-MAILDSrv.ps1             # 重啟 Raiden MailD
├── Example.ps1                      # 範例
└── README.md                        # 說明文件
```
## 功能說明
### 1. Validate-CerCertificate.ps1
負責檢查新憑證是否有效：
* 憑證是否能載入
* CN 是否符合
* 憑證鏈結是否完整
* CRL / OCSP 是否通過
* 是否過期
* 若無效，會回傳對應錯誤碼。
### 2. Compare-CerCertificates.ps1
負責比對新舊憑證是否需要更新：
* 新憑證是否有效（呼叫 Validate）
* CN 是否一致
* Thumbprint 是否不同
* NotAfter 是否較新
* 防呆：檔案是否存在、是否可讀取、Validator 是否可執行

回傳錯誤碼：
|錯誤碼|意義|
| ------------- |:-------------:|
|0|新憑證有效且較新，需要更新|
|10|無需更新（相同或較舊）|
|其他|Validate 回傳的錯誤碼|

### 3. Deploy-Certificate.ps1
負責真正執行部署：
* 呼叫 Compare
* 若 Compare 回傳 0 → 執行部署
* 備份舊憑證（含 timestamp）
* 覆蓋新憑證
* 寫入 Log

Log 格式：
```
yyyy-MM-dd HH:mm:ss    message

```
## 使用方式
敬請參閱 example.ps1

## Log 檔案
預設會寫入：
```
.\deploy_cert.log
```
內容包含：
* Compare 結果
* 部署流程
* 備份檔案路徑
* 服務重啟結果
## 系統需求
* Windows Server 2012 / 2012 R2
* PowerShell 4.0
* Raiden MailD
