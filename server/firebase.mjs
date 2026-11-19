import { getApps,initializeApp,cert,applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { StoreError } from './orders.mjs';
export function services() {
  if (!getApps().length) {
    if (!process.env.FIREBASE_SERVICE_ACCOUNT && !process.env.GOOGLE_APPLICATION_CREDENTIALS && !process.env.FIRESTORE_EMULATOR_HOST) throw new StoreError('Store backend is awaiting Firebase configuration',503);
    initializeApp({credential:process.env.FIREBASE_SERVICE_ACCOUNT ? cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)) : applicationDefault(),projectId:process.env.FIREBASE_PROJECT_ID || 'verve-store-gamal6507'});
  }
  return {auth:getAuth(),db:getFirestore()};
}
export async function identify(req,auth) {
  const match = /^Bearer (\S+)$/.exec(req.headers.authorization || '');
  if (!match) throw new StoreError('Authentication required',401);
  try { return await auth.verifyIdToken(match[1],true); }
  catch { throw new StoreError('Sign in again to continue',401); }
}
