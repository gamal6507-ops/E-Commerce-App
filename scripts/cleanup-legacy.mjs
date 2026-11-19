// Run only against an explicitly selected project. Default is a read-only dry run.
import {initializeApp,applicationDefault} from 'firebase-admin/app';
import {getFirestore,FieldValue,FieldPath} from 'firebase-admin/firestore';
if(!process.env.FIREBASE_PROJECT_ID) throw new Error('Set FIREBASE_PROJECT_ID explicitly');
initializeApp({credential:applicationDefault(),projectId:process.env.FIREBASE_PROJECT_ID});
const db=getFirestore();const apply=process.argv.includes('--apply');
let cursor;let profiles=0,cards=0;
while(true){
 let query=db.collection('users').orderBy(FieldPath.documentId()).limit(100);
 if(cursor)query=query.startAfter(cursor);
 const page=await query.get();if(page.empty)break;
 for(const user of page.docs){
  if('password' in user.data()){profiles++;if(apply)await user.ref.update({password:FieldValue.delete()});}
  const saved=await user.ref.collection('paymentCards').get();cards+=saved.size;
  if(apply)for(const card of saved.docs)await db.recursiveDelete(card.ref);
 }
 cursor=page.docs.at(-1);
}
console.log(JSON.stringify({mode:apply?'applied':'dry-run',profilesWithPassword:profiles,legacyCards:cards}));
