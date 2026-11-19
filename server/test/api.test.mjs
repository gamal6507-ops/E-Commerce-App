import test from 'node:test';
import assert from 'node:assert/strict';
import {createHandler} from '../../api/store.mjs';

function response(){return {headers:{},setHeader(k,v){this.headers[k]=v;},status(code){this.code=code;return this;},json(data){this.data=data;return this;}};}
const db={collection(){return {doc(){return {};}};}};
test('API rejects missing or invalid Firebase identity',async()=>{
 const handler=createHandler(()=>({db,auth:{async verifyIdToken(){throw new Error('Invalid');}}}));
 for(const headers of [{},{authorization:'Bearer expired'}]){
  const res=response();await handler({method:'GET',headers,query:{action:'orders'}},res);
  assert.equal(res.code,401);
 }
});
test('non-admin cannot read all orders or write catalog',async()=>{
 const handler=createHandler(()=>({db,auth:{async verifyIdToken(){return {uid:'alice',admin:false};}}}));
 for(const [action,method,query] of [['orders','GET',{admin:'true'}],['product','POST',{}]]){
  const res=response();await handler({method,headers:{authorization:'Bearer fixture'},query:{action,...query},body:{}},res);
  assert.equal(res.code,403);
 }
});
test('invalid checkout IDs cannot select a different data path',async()=>{
 const handler=createHandler(()=>({db,auth:{async verifyIdToken(){return {uid:'alice'};}}}));
 const res=response();await handler({method:'POST',headers:{authorization:'Bearer fixture'},query:{action:'checkout'},body:{requestId:'../../orders/other',addressId:'x/y'}},res);
 assert.equal(res.code,400);
});
