import controlP5.*;
import processing.sound.*;
import processing.video.*; //ビデオを利用する際に必要
import jp.nyatla.nyar4psg.*; //NyARToolkitを利用する際に必要
SoundFile draw;
SoundFile shot;
ControlP5 slider;

int camNo = 0;
Capture cam;
MultiMarker nya;

PMatrix3D markerMatrix0, markerMatrix1, markerMatrix2, markerMatrix3; //マーカ座標系への変換行列

//<---
PVector pos0;
PVector pos1;
PVector pos2;
PVector pos3;

final float bowLen = 0.7;
float[] arrowPower = new float[100];

float[] arrowPosx = new float[100];
float[] arrowPosy = new float[100];
float[] arrowPosz = new float[100];
float[] arrowVecx = new float[100];
float[] arrowVecy = new float[100];
float[] arrowVecz = new float[100];

float[] boxPosx = new float[100];
float[] boxPosy = new float[100];
float[] boxPosz = new float[100];

int[] judgeCount = new int[100];

float arrowSpeed;
float sliderSpeed;
final float boxLine = 80.0;

int arrowCount = 0;
int boxCount = 0;

boolean bowSet;
boolean bowDraw;
boolean bowRelease;

boolean boxSet;

//--->

void setup()
{
  size(1280, 960, P3D);
  
  //<---
  for (int i = 0; i < 100; i++){
    arrowPower[i] = 0;
  }

  slider = new ControlP5(this);
  slider.addSlider("sliderSpeed")
    .setRange(0,100)
    .setValue(50)
    .setPosition(50,40)
    .setSize(200,20)
    .setNumberOfTickMarks(5);//Rangeを(引数の数-1)で割った値が1メモリの値
   //スライダーの現在値の表示位置
   slider.getController("sliderSpeed")
     .getValueLabel()
     .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE)//位置、外側の右寄せ
     .setPaddingX(-20);//padding値をとる alineで設定したRIGHTからのpadding
  
  strokeWeight(4);
  draw = new SoundFile(this, "arrowDraw.mp3");
   shot = new SoundFile(this, "arrowFly.mp3");
  //--->
  
  String[] cameras = Capture.list(); //利用可能なカメラ一覧を取得
  println("利用可能カメラ一覧");
  for (int i = 0; i < cameras.length; i++) {  //一覧を表示
    println("[" + i + "] " + cameras[i]);
  }
  println("-------------------------------");
  cam = new Capture(this, cameras[camNo]); //カメラに接続
  println("接続中のカメラ；[" + camNo + "] " + cameras[camNo]);
  nya=new MultiMarker(this, width, height, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
  
  
  //マーカ用画像の登録
  nya.addNyIdMarker(0, 80);//id=0
  nya.addNyIdMarker(1, 80);//id=1
  nya.addNyIdMarker(2, 80);//id=2
  nya.addNyIdMarker(3, 80);//id=3
  ;
  
  cam.start(); //カメラ撮影開始
}

void draw() {
  
  if (cam.available() !=true) {
    return;
  }
  
  cam.read();//カメラから画像を読み込み
  //  //画像の反転
  //PImage flipImage = cam.get();
  //for (int y = 0; y < cam.height; y++){
  //  for (int x = 0; x < cam.width; x++){
  //    flipImage.pixels[x+(flipImage.width*y)]=cam.pixels[(width-x-1)+(cam.width*(cam.height-y-1))];
  //  }
  //}

  nya.detect(cam);//マーカの認識
  background(0);
  nya.drawBackground(cam);//frustumを考慮した背景描画
  
  //-----------------------------------------------------------------------
  //スライダーの設定
  arrowSpeed = 0.05 + (sliderSpeed / 100);
  
  //パワーの表示
  //fill(0,255,0);
  //stroke(0);
  //pushMatrix();
  //  translate(100,100,0);
  //  box(arrowPower[arrowCount] * 100,10,10);
  //popMatrix();
  
  
  //０マーカ（弓）の処理
  if (nya.isExist(0)) { //0番のマーカーが存在するか確認
    nya.beginTransform(0);//マーカ0座標系に設定(マーカ上に原点が来るように座標系が変わる)
    markerMatrix0 = nya.getMatrix(0);//マーカ0からカメラ座標系への変換行列の取得
    
    //<---
    ground();
    
    //ポールの影
    fill(0,0,100); //塗りつぶしをなくす
    noStroke();
    pushMatrix();
    rotateX(PI/2);
    pillar(2,5,5);
    popMatrix();
    
    //ポール
    noStroke();
    fill(255,0,0);
    pushMatrix();
        translate(0, 0, 50);//オブジェクト座標をZ方向に移動（立方体がめり込まないように）
        rotateX(PI/2);
        pillar(20,5,5);
    popMatrix();
    
    pos0 = new PVector(0,0,50);
    
    //---->
    nya.endTransform();  //マーカ0座標系を終了して元のスクリーン座標系に変換
  }
  
  //----------------------------------------------------------------------------------
  //マーカ1（ポール１）に対する処理
  if (nya.isExist(1)) { //マーカー1が存在するか確認
    nya.beginTransform(1);//マーカ1座標系に設定(マーカ上に原点が来るように座標系が変わる)
    markerMatrix1 = nya.getMatrix(1); //マーカ1の姿勢行列を取得(マーカ１の座標系ー＞カメラ座標系への変換行列)
    //<---
    ground();  
    //ポール
    noStroke();
    fill(53,29,9);
    pushMatrix();
        translate(0, 0, 50);//オブジェクト座標をZ方向に移動（立方体がめり込まないように）
        rotateX(PI/2);
        pillar(100,5,5);
    popMatrix();
    
    pos1 = new PVector(0,0,50);
    
    //---->
    nya.endTransform();  //マーカ1座標系を終了して元のスクリーン座標系に変換
  
}

  //マーカ3(box)に対する処理
  if (nya.isExist(3)) { //マーカー3が存在するか確認
    nya.beginTransform(3);//マーカ3座標系に設定(マーカ上に原点が来るように座標系が変わる)
    markerMatrix3 = nya.getMatrix(3); //マーカ1の姿勢行列を取得(マーカ１の座標系ー＞カメラ座標系への変換行列)
    //<---
    //ground();
    stroke(0);
    fill(255,0,0);
    pushMatrix();
      translate(0,0,20);
      box(boxLine);
    popMatrix();
    pos3 = new PVector(0,0,0);
    
    //---->
    nya.endTransform();  //マーカ1座標系を終了して元のスクリーン座標系に変換
  }
  
    //----------------------------------------------------------------------------------
    //マーカ2(ポール２)に対する処理
  if (nya.isExist(2)) { //マーカー2が存在するか確認
    nya.beginTransform(2);//マーカ2座標系に設定(マーカ上に原点が来るように座標系が変わる)
    // マーカ2の座標系で当たり判定
    markerMatrix2 = nya.getMatrix(2); //マーカ2の姿勢行列を取得(マーカ2の座標系ー＞カメラ座標系への変換行列)
    //<---
    ground();
      //ポール
    noStroke();
    fill(53,29,9);
    pushMatrix();
      translate(0, 0, 50);//オブジェクト座標をZ方向に移動（立方体がめり込まないように）
      rotateX(PI/2);
      pillar(100,5,5);
    popMatrix();
    
    pos2 = new PVector(0,0,50);
   PVector pos1_2 = new PVector();
    PVector pos0_2 = new PVector();
    PVector pos3_2 = new PVector();
    //---->
    nya.endTransform();  //マーカ2座標系を終了して元のスクリーン座標系に変換    
    
    //-------弓矢全体-----------
    if(markerMatrix1 != null && markerMatrix0 != null && markerMatrix3 != null){
      nya.beginTransform(2);//マーカ2座標系に設定(マーカ上に原点が来るように座標系が変わる)
      
      //マーカー０の位置を取得
      markerMatrix2 = nya.getMatrix(2); //マーカ2の姿勢行列を取得(マーカ2の座標系ー＞カメラ座標系への変換行列)
      markerMatrix2.invert(); //markerMatrix2の逆行列を求める
       markerMatrix2.apply(markerMatrix0); //markerMatrix2^-2 * markerMatrix0（マーカ1の座標系をマーカ2の座標系に変換する行列)
       markerMatrix2.mult(pos0, pos0_2); //ボールの位置をマーカ1の座標系からマーカ2の座標系に変換    
       
       //マーカー１の情報を取得
       markerMatrix2 = nya.getMatrix(2); //マーカ2の姿勢行列を取得(マーカ2の座標系ー＞カメラ座標系への変換行列)
       markerMatrix2.invert(); //markerMatrix2の逆行列を求める 
       markerMatrix2.apply(markerMatrix1); //markerMatrix2^-2 * markerMatrix0（マーカ1の座標系をマーカ2の座標系に変換する行列)
       markerMatrix2.mult(pos1, pos1_2); //ボールの位置をマーカ1の座標系からマーカ2の座標系に変換  
       
       //マーカー3の情報を取得
       markerMatrix2 = nya.getMatrix(2); 
       markerMatrix2.invert(); 
       markerMatrix2.apply(markerMatrix3); 
       markerMatrix2.mult(pos3, pos3_2); 
       
       //線を記述していく
       markerMatrix2 = nya.getMatrix(2); //マーカ2の姿勢行列を取得(マーカ2の座標系ー＞カメラ座標系への変換行列)
       
       float[] bowVec01 = {pos1_2.x - pos0_2.x, pos1_2.y - pos0_2.y, pos1_2.z - pos0_2.z};
       float[] bowVec02 = {pos2.x - pos0_2.x, pos2.y - pos0_2.y, pos2.z - pos0_2.z};
       float[] bowVecTop  = {(bowVec01[0] + bowVec02[0])*bowLen, (bowVec01[1] + bowVec02[1])*bowLen, (bowVec01[2] + bowVec02[2])*bowLen};
       float[] bowPosTop = {bowVecTop[0] + pos0_2.x, bowVecTop[1] + pos0_2.y, bowVecTop[2] + pos0_2.z};
       float bowLength = sqrt(sq(bowVecTop[0]) + sq(bowVecTop[1]) + sq(bowVecTop[2]));
     
       float[] bowBackVec01 = {-bowVec01[0],-bowVec01[1],-bowVec01[2]};
       float[] bowBackVec02 = {-bowVec02[0],-bowVec02[1],-bowVec02[2]};
       float[] bowBackPos1 = {bowBackVec01[0] + pos0_2.x, bowBackVec01[1] + pos0_2.y, bowBackVec01[2] + pos0_2.z};
       float[] bowBackPos2 = {bowBackVec02[0] + pos0_2.x, bowBackVec02[1] + pos0_2.y, bowBackVec02[2] + pos0_2.z};
       
       //1-2（弦）
       noFill();
       stroke(0);
       curve(bowBackPos1[0],bowBackPos1[1],bowBackPos1[2],pos2.x,pos2.y,pos2.z,pos1_2.x,pos1_2.y,pos1_2.z,bowBackPos2[0],bowBackPos2[1],bowBackPos2[2]);
       
      if(bowLength > 60){ 
      stroke(224,211,203);
      }else stroke(255,0,0);
      //0-2
      line(pos2.x,pos2.y,pos2.z,pos0_2.x,pos0_2.y,pos0_2.z);    
       //0-1
      line(pos1_2.x,pos1_2.y,pos1_2.z,pos0_2.x,pos0_2.y,pos0_2.z);
       
        
        if(frameCount%10 == 1){
        //println(bowLength);
        }
       
       if(bowSet == true && bowLength < 60){
         bowDraw = true;
         draw.play();
       }
       
       //--------------------------------
       if(bowDraw == true){
         //矢
         stroke(0,255,0);
         line(pos0_2.x,pos0_2.y,pos0_2.z,bowPosTop[0],bowPosTop[1],bowPosTop[2]);
         if(bowLength < 800){
         draw.amp(0.2 + (bowLength/800) * 0.8);
         shot.amp(0.2 + (bowLength/800) * 0.8);
         }else {
           draw.amp(1);
           shot.amp(1);
         }
       }
       
        //パワーを設定
         //arrowPower[arrowCount] = sqrt(sq(arrowVecx[arrowCount]) + sq(arrowVecy[arrowCount]) + sq(arrowVecz[arrowCount]));
       
      if(bowRelease == true){
        draw.stop();
        if(bowDraw == true){
        shot.play();
        arrowPosx[arrowCount] = bowPosTop[0];
        arrowPosy[arrowCount] = bowPosTop[1];
        arrowPosz[arrowCount] = bowPosTop[2];
        
        arrowVecx[arrowCount] = bowVecTop[0];
        arrowVecy[arrowCount] = bowVecTop[1];
        arrowVecz[arrowCount] = bowVecTop[2];
        
        arrowCount++;
        }
        bowDraw = false;
        bowRelease = false;
      }
      
      //飛ばした弓矢
      for(int i = 0; i < arrowCount; i++){
        stroke(0,255,0);
        line(arrowPosx[i], arrowPosy[i], arrowPosz[i], arrowPosx[i] - arrowVecx[i] , arrowPosy[i] - arrowVecy[i], arrowPosz[i] - arrowVecz[i]);
        arrowPosx[i] += arrowVecx[i]  * arrowSpeed;
        arrowPosy[i] += arrowVecy[i]  *arrowSpeed;
        arrowPosz[i] += arrowVecz[i]  * arrowSpeed;
      }
      
      //CONTROLが押された時、箱の位置情報を取得
      if(boxSet == true){
        boxPosx[boxCount] = pos3_2.x;
        boxPosy[boxCount] = pos3_2.y;
        boxPosz[boxCount] = pos3_2.z;
        boxCount++;
      }
      //箱を表示

      for(int i = 0; i < boxCount; i++){
        for(int k = 0; k < arrowCount; k++){
          judgeCount[i] += judge(boxPosx[i],boxPosy[i],boxPosz[i],arrowPosx[k],arrowPosy[k],arrowPosz[k]);
        }
        if(judgeCount[i]==0){
          pushMatrix();
            translate(boxPosx[i], boxPosy[i], boxPosz[i]+boxLine/2);
             stroke(0);
             fill(255);
            box(boxLine);
          popMatrix();
          
          pushMatrix();
            translate(boxPosx[i], boxPosy[i], 0);
             noStroke();
             fill(0,0,0,100);
            box(boxLine,boxLine,1);
          popMatrix();
        }
        else if(judgeCount[i] == 1){
            pushMatrix();
            translate(boxPosx[i], boxPosy[i], boxPosz[i]+boxLine/2);
             stroke(0);
             fill(255,0,0);
            box(boxLine);
          popMatrix();
        }
      }
      
       //設定
       bowSet = false;
       boxSet = false;
       
       nya.endTransform();  //マーカ2座標系を終了して元のスクリーン座標系に変換    
    }
  } 
  
}

void keyPressed(){
  //矢の準備
  if(keyCode == SHIFT){
    bowSet = true;
  }
  //箱の準備
  if(keyCode == CONTROL){
    boxSet = true;
  }
}

int judge(float boxX, float boxY, float boxZ, float arrowX, float arrowY, float arrowZ){
  int test = 0;
  if( (arrowX > boxX -boxLine/2) && (arrowX < boxX + boxLine/2)){
    if((arrowY > boxY -boxLine/2) && (arrowY < boxY + boxLine/2)){
      if((arrowZ > boxZ -boxLine/2) && (arrowZ < boxZ + boxLine/2)){
        test += 1;
      }
    }
  }else test = 0;
  
  return test;
}

void keyReleased(){
  if(keyCode == SHIFT){
    bowRelease = true;
  }
}

//地面の関数
void ground(){
    fill(255);
    noStroke();
    box(100,100,1);
}

//円柱の関数
void pillar(float length, float radius1 , float radius2){
float x,y,z;
pushMatrix();
//上面の作成
beginShape(TRIANGLE_FAN);
y = -length / 2;
vertex(0, y, 0);
for(int deg = 0; deg <= 360; deg = deg + 10){
x = cos(radians(deg)) * radius1;
z = sin(radians(deg)) * radius1;
vertex(x, y, z);
}
endShape();              //底面の作成
beginShape(TRIANGLE_FAN);
y = length / 2;
vertex(0, y, 0);
for(int deg = 0; deg <= 360; deg = deg + 10){
x = cos(radians(deg)) * radius2;
z = sin(radians(deg)) * radius2;
vertex(x, y, z);
}
endShape();
//側面の作成
beginShape(TRIANGLE_STRIP);
for(int deg =0; deg <= 360; deg = deg + 5){
x = cos(radians(deg)) * radius1;
y = -length / 2;
z = sin(radians(deg)) * radius1;
vertex(x, y, z);
x = cos(radians(deg)) * radius2;
y = length / 2;
z = sin(radians(deg)) * radius2;
vertex(x, y, z);
}
endShape();
popMatrix();
}
