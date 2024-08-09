/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// import {onRequest} from "firebase-functions/v2/https";
// import * as logger from "firebase-functions/logger";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";
import * as fs from "fs";
import * as path from "path";

admin.initializeApp();

/**
 * config.jsonファイルを読み込み、設定をJSONオブジェクトとして返す
 * @return {object} 設定オブジェクト
 */
function loadConfig() {
  const configPath = path.join(__dirname, "../../assets/config.json");
  const configData = fs.readFileSync(configPath, "utf8");
  return JSON.parse(configData);
}

export const verifyPurchase = functions.https.onCall(async (data, context) => {
  const {receiptData} = data;
  const productionUrl = "https://buy.itunes.apple.com/verifyReceipt";
  const sandboxUrl = "https://sandbox.itunes.apple.com/verifyReceipt";

  const config = loadConfig();
  const appStoreConnectApiKey = config.appStoreConnectApiKey;

  async function verifyWithEnvironment(url: string) {
    try {
      const response = await axios.post(url, {
        "receipt-data": receiptData,
        "password": appStoreConnectApiKey,
      });

      if (response.data.status === 0) {
        return {isValid: true, data: response.data};
      } else if (response.data.status === 21007 && url === productionUrl) {
        // サンドボックスレシートが本番環境で使用された場合、サンドボックス環境で再試行
        return null;
      } else {
        return {isValid: false, error: `検証エラー: ${response.data.status}`};
      }
    } catch (error) {
      console.error("検証中にエラーが発生しました:", error);
      return {isValid: false, error: "サーバーエラー"};
    }
  }

  // まず本番環境で検証
  let result = await verifyWithEnvironment(productionUrl);
  
  // 本番環境での検証が失敗した場合、サンドボックス環境で再試行
  if (result === null) {
    result = await verifyWithEnvironment(sandboxUrl);
  }

  return result;
});

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });