package com.pda.uhf_g.ui.activity;

import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.RectF;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.pda.uhf_g.R;
import com.pda.uhf_g.ui.view.MaskImageView;
import com.pda.uhf_g.ui.view.PaintImageView;

/**
 * 高级拍照Activity
 * 支持遮罩模式和涂抹模式的图像裁剪
 */
public class AdvancedCameraActivity extends AppCompatActivity {
    
    private static final int REQUEST_IMAGE_CAPTURE = 1001;
    
    private ImageView ivPhoto;
    private MaskImageView maskImageView;
    private PaintImageView paintImageView;
    private Button btnSwitchMode;
    private Button btnConfirmCrop;
    private Button btnRetakePhoto;
    private TextView tvModeTitle;
    
    private Bitmap originalBitmap;
    private boolean isMaskMode = true; // true = 遮罩模式, false = 涂抹模式
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_advanced_camera);
        
        initViews();
        setupListeners();
        
        // 自动启动相机
        startCamera();
    }
    
    private void initViews() {
        ivPhoto = findViewById(R.id.iv_photo);
        maskImageView = findViewById(R.id.mask_image_view);
        paintImageView = findViewById(R.id.paint_image_view);
        btnSwitchMode = findViewById(R.id.btn_switch_mode);
        btnConfirmCrop = findViewById(R.id.btn_confirm_crop);
        btnRetakePhoto = findViewById(R.id.btn_retake_photo);
        tvModeTitle = findViewById(R.id.tv_mode_title);
        
        updateModeUI();
    }
    
    private void setupListeners() {
        btnSwitchMode.setOnClickListener(v -> switchMode());
        btnConfirmCrop.setOnClickListener(v -> confirmCrop());
        btnRetakePhoto.setOnClickListener(v -> startCamera());
    }
    
    private void startCamera() {
        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (takePictureIntent.resolveActivity(getPackageManager()) != null) {
            startActivityForResult(takePictureIntent, REQUEST_IMAGE_CAPTURE);
        }
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        if (requestCode == REQUEST_IMAGE_CAPTURE && resultCode == RESULT_OK) {
            Bundle extras = data.getExtras();
            originalBitmap = (Bitmap) extras.get("data");
            
            if (originalBitmap != null) {
                showPhotoEditingView();
            }
        } else {
            // 用户取消拍照，返回上一页
            finish();
        }
    }
    
    private void showPhotoEditingView() {
        ivPhoto.setImageBitmap(originalBitmap);
        ivPhoto.setVisibility(View.VISIBLE);
        
        if (isMaskMode) {
            maskImageView.setImageBitmap(originalBitmap);
            maskImageView.setVisibility(View.VISIBLE);
            paintImageView.setVisibility(View.GONE);
        } else {
            paintImageView.setImageBitmap(originalBitmap);
            paintImageView.setVisibility(View.VISIBLE);
            maskImageView.setVisibility(View.GONE);
        }
        
        btnSwitchMode.setVisibility(View.VISIBLE);
        btnConfirmCrop.setVisibility(View.VISIBLE);
        btnRetakePhoto.setVisibility(View.VISIBLE);
    }
    
    private void switchMode() {
        isMaskMode = !isMaskMode;
        updateModeUI();
        
        if (originalBitmap != null) {
            showPhotoEditingView();
        }
    }
    
    private void updateModeUI() {
        if (isMaskMode) {
            tvModeTitle.setText(getString(R.string.photo_mask_mode));
            btnSwitchMode.setText(getString(R.string.switch_to_paint_mode));
        } else {
            tvModeTitle.setText(getString(R.string.photo_paint_mode));
            btnSwitchMode.setText(getString(R.string.switch_to_mask_mode));
        }
    }
    
    private void confirmCrop() {
        if (originalBitmap == null) {
            Toast.makeText(this, "请先拍照", Toast.LENGTH_SHORT).show();
            return;
        }
        
        Bitmap croppedBitmap;
        
        if (isMaskMode) {
            // 遮罩模式：裁剪中央矩形区域
            croppedBitmap = maskImageView.getCroppedBitmap();
        } else {
            // 涂抹模式：只保留涂抹区域
            croppedBitmap = paintImageView.getCroppedBitmap();
        }
        
        if (croppedBitmap != null) {
            // 返回裁剪后的图片
            Intent resultIntent = new Intent();
            resultIntent.putExtra("cropped_bitmap", croppedBitmap);
            setResult(RESULT_OK, resultIntent);
            finish();
        } else {
            Toast.makeText(this, "请选择识别区域", Toast.LENGTH_SHORT).show();
        }
    }
}