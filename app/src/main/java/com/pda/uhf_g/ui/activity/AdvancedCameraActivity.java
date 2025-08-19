package com.pda.uhf_g.ui.activity;

import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.FileProvider;

import com.pda.uhf_g.R;
import com.pda.uhf_g.ui.view.MaskImageView;
import com.pda.uhf_g.ui.view.PaintImageView;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * 高级拍照Activity - 简化版，逐步排查闪退问题
 */
public class AdvancedCameraActivity extends AppCompatActivity {
    
    private static final String TAG = "AdvancedCamera";
    private static final int REQUEST_IMAGE_CAPTURE = 1001;
    private static final int REQUEST_IMAGE_CAPTURE_SIMPLE = 2001;
    
    private ImageView ivPhoto;
    private MaskImageView maskImageView;
    private PaintImageView paintImageView;
    private Button btnSwitchMode;
    private Button btnConfirmCrop;
    private Button btnRetakePhoto;
    private TextView tvModeTitle;
    
    private Bitmap originalBitmap;
    private boolean isMaskMode = true;
    private String currentPhotoPath;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.d(TAG, "onCreate start");
        super.onCreate(savedInstanceState);
        
        try {
            Log.d(TAG, "Setting content view");
            setContentView(R.layout.activity_advanced_camera);
            
            Log.d(TAG, "Initializing views");
            initViewsSafely();
            
            Log.d(TAG, "Setting up listeners");
            setupListenersSafely();
            
            Log.d(TAG, "Starting simple camera");
            // 先用最简单的方式启动相机
            startSimpleCamera();
            
        } catch (Exception e) {
            Log.e(TAG, "Fatal error in onCreate: " + e.getMessage(), e);
            showErrorAndFinish("初始化失败: " + e.getMessage());
        }
    }
    
    private void initViewsSafely() {
        try {
            ivPhoto = findViewById(R.id.iv_photo);
            maskImageView = findViewById(R.id.mask_image_view);
            paintImageView = findViewById(R.id.paint_image_view);
            btnSwitchMode = findViewById(R.id.btn_switch_mode);
            btnConfirmCrop = findViewById(R.id.btn_confirm_crop);
            btnRetakePhoto = findViewById(R.id.btn_retake_photo);
            tvModeTitle = findViewById(R.id.tv_mode_title);
            
            // 检查关键组件
            if (ivPhoto == null || maskImageView == null || paintImageView == null) {
                throw new RuntimeException("关键视图组件初始化失败");
            }
            
            updateModeUI();
            Log.d(TAG, "Views initialized successfully");
            
        } catch (Exception e) {
            Log.e(TAG, "Error initializing views: " + e.getMessage(), e);
            throw e;
        }
    }
    
    private void setupListenersSafely() {
        try {
            if (btnSwitchMode != null) {
                btnSwitchMode.setOnClickListener(v -> switchMode());
            }
            if (btnConfirmCrop != null) {
                btnConfirmCrop.setOnClickListener(v -> confirmCrop());
            }
            if (btnRetakePhoto != null) {
                btnRetakePhoto.setOnClickListener(v -> startSimpleCamera());
            }
            Log.d(TAG, "Listeners set up successfully");
        } catch (Exception e) {
            Log.e(TAG, "Error setting up listeners: " + e.getMessage(), e);
            throw e;
        }
    }
    
    private void startSimpleCamera() {
        Log.d(TAG, "尝试启动高分辨率拍照模式");
        
        // 第一步：尝试高分辨率模式
        if (tryHighResolutionCamera()) {
            return; // 成功启动高分辨率模式
        }
        
        // 第二步：降级到简单模式
        Log.w(TAG, "高分辨率模式失败，使用简单模式");
        try {
            Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            if (takePictureIntent.resolveActivity(getPackageManager()) != null) {
                Log.d(TAG, "启动简单拍照模式");
                startActivityForResult(takePictureIntent, REQUEST_IMAGE_CAPTURE_SIMPLE);
            } else {
                showErrorAndFinish("未找到相机应用");
            }
        } catch (Exception e) {
            Log.e(TAG, "启动简单相机失败: " + e.getMessage(), e);
            showErrorAndFinish("启动相机失败: " + e.getMessage());
        }
    }
    
    // 新增：安全的高分辨率拍照尝试
    private boolean tryHighResolutionCamera() {
        try {
            Log.d(TAG, "尝试创建高分辨率图片文件");
            
            // 创建临时文件
            String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(new Date());
            String imageFileName = "OCR_" + timeStamp + ".jpg";
            
            // 尝试使用外部缓存目录（更安全）
            File storageDir = getExternalCacheDir();
            if (storageDir == null) {
                Log.w(TAG, "外部缓存目录不可用，尝试内部缓存");
                storageDir = getCacheDir();
            }
            
            if (storageDir == null || !storageDir.exists()) {
                Log.w(TAG, "缓存目录不可用");
                return false;
            }
            
            File photoFile = new File(storageDir, imageFileName);
            currentPhotoPath = photoFile.getAbsolutePath();
            Log.d(TAG, "创建图片文件: " + currentPhotoPath);
            
            // 尝试创建URI
            Uri photoURI;
            try {
                photoURI = FileProvider.getUriForFile(this,
                        "com.pda.uhf_g.fileprovider", photoFile);
                Log.d(TAG, "成功创建URI: " + photoURI);
            } catch (Exception e) {
                Log.w(TAG, "FileProvider创建URI失败: " + e.getMessage());
                return false;
            }
            
            // 启动高分辨率拍照
            Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            if (takePictureIntent.resolveActivity(getPackageManager()) != null) {
                takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI);
                Log.d(TAG, "启动高分辨率拍照");
                startActivityForResult(takePictureIntent, REQUEST_IMAGE_CAPTURE);
                return true;
            } else {
                Log.w(TAG, "未找到相机应用");
                return false;
            }
            
        } catch (Exception e) {
            Log.w(TAG, "高分辨率模式设置失败: " + e.getMessage(), e);
            return false;
        }
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        Log.d(TAG, "onActivityResult: requestCode=" + requestCode + ", resultCode=" + resultCode);
        super.onActivityResult(requestCode, resultCode, data);
        
        try {
            if (resultCode == RESULT_OK) {
                if (requestCode == REQUEST_IMAGE_CAPTURE_SIMPLE) {
                    handleSimpleCameraResult(data);
                } else if (requestCode == REQUEST_IMAGE_CAPTURE) {
                    handleHighResCameraResult();
                }
            } else {
                Log.d(TAG, "用户取消拍照或拍照失败");
                finish();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in onActivityResult: " + e.getMessage(), e);
            showErrorAndFinish("处理拍照结果失败: " + e.getMessage());
        }
    }
    
    private void handleSimpleCameraResult(@Nullable Intent data) {
        try {
            if (data != null && data.getExtras() != null) {
                Bundle extras = data.getExtras();
                originalBitmap = (Bitmap) extras.get("data");
                
                if (originalBitmap != null) {
                    int width = originalBitmap.getWidth();
                    int height = originalBitmap.getHeight();
                    Log.d(TAG, "简单模式获得图片: " + width + "x" + height);
                    
                    if (width < 100 && height < 100) {
                        Log.w(TAG, "图片分辨率过低，可能影响OCR效果");
                        Toast.makeText(this, "图片分辨率较低，可能影响识别效果", Toast.LENGTH_LONG).show();
                    }
                    
                    showPhotoEditingView();
                } else {
                    showErrorAndFinish("无法获取拍照图片");
                }
            } else {
                showErrorAndFinish("拍照数据为空");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error handling simple camera result: " + e.getMessage(), e);
            showErrorAndFinish("处理拍照结果失败: " + e.getMessage());
        }
    }
    
    private void handleHighResCameraResult() {
        Log.d(TAG, "处理高分辨率拍照结果");
        
        try {
            if (currentPhotoPath == null) {
                Log.e(TAG, "图片路径为空");
                showErrorAndFinish("图片路径丢失");
                return;
            }
            
            File photoFile = new File(currentPhotoPath);
            if (!photoFile.exists()) {
                Log.e(TAG, "图片文件不存在: " + currentPhotoPath);
                showErrorAndFinish("图片文件不存在");
                return;
            }
            
            Log.d(TAG, "开始加载高分辨率图片: " + currentPhotoPath);
            
            // 安全地加载图片
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(currentPhotoPath, options);
            
            int imageWidth = options.outWidth;
            int imageHeight = options.outHeight;
            Log.d(TAG, "原始图片尺寸: " + imageWidth + "x" + imageHeight);
            
            if (imageWidth <= 0 || imageHeight <= 0) {
                Log.e(TAG, "图片尺寸无效");
                showErrorAndFinish("图片数据无效");
                return;
            }
            
            // 计算合适的采样率 - 保持高质量但避免内存问题
            int maxDimension = 2048;
            int sampleSize = 1;
            
            while ((imageWidth / sampleSize) > maxDimension || (imageHeight / sampleSize) > maxDimension) {
                sampleSize *= 2;
            }
            
            Log.d(TAG, "使用采样率: " + sampleSize);
            
            // 加载图片
            options.inJustDecodeBounds = false;
            options.inSampleSize = sampleSize;
            options.inPreferredConfig = Bitmap.Config.ARGB_8888;
            
            originalBitmap = BitmapFactory.decodeFile(currentPhotoPath, options);
            
            if (originalBitmap != null) {
                Log.d(TAG, "高分辨率图片加载成功: " + originalBitmap.getWidth() + "x" + 
                          originalBitmap.getHeight());
                showPhotoEditingView();
            } else {
                Log.e(TAG, "图片解码失败");
                showErrorAndFinish("图片解码失败");
            }
            
        } catch (OutOfMemoryError e) {
            Log.e(TAG, "内存不足: " + e.getMessage(), e);
            showErrorAndFinish("图片过大，内存不足");
        } catch (Exception e) {
            Log.e(TAG, "处理高分辨率图片失败: " + e.getMessage(), e);
            showErrorAndFinish("图片处理失败: " + e.getMessage());
        }
    }
    
    private void showPhotoEditingView() {
        try {
            Log.d(TAG, "Showing photo editing view");
            
            if (ivPhoto != null && originalBitmap != null) {
                ivPhoto.setImageBitmap(originalBitmap);
                ivPhoto.setVisibility(View.VISIBLE);
            }
            
            if (isMaskMode && maskImageView != null) {
                maskImageView.setImageBitmap(originalBitmap);
                maskImageView.setVisibility(View.VISIBLE);
                if (paintImageView != null) {
                    paintImageView.setVisibility(View.GONE);
                }
            } else if (!isMaskMode && paintImageView != null) {
                paintImageView.setImageBitmap(originalBitmap);
                paintImageView.setVisibility(View.VISIBLE);
                if (maskImageView != null) {
                    maskImageView.setVisibility(View.GONE);
                }
            }
            
            // 显示操作按钮
            if (btnSwitchMode != null) btnSwitchMode.setVisibility(View.VISIBLE);
            if (btnConfirmCrop != null) btnConfirmCrop.setVisibility(View.VISIBLE);
            if (btnRetakePhoto != null) btnRetakePhoto.setVisibility(View.VISIBLE);
            
            Log.d(TAG, "Photo editing view shown successfully");
            
        } catch (Exception e) {
            Log.e(TAG, "Error showing photo editing view: " + e.getMessage(), e);
            showErrorAndFinish("显示编辑界面失败: " + e.getMessage());
        }
    }
    
    private void switchMode() {
        try {
            isMaskMode = !isMaskMode;
            updateModeUI();
            
            if (originalBitmap != null) {
                showPhotoEditingView();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error switching mode: " + e.getMessage(), e);
            Toast.makeText(this, "切换模式失败: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }
    
    private void updateModeUI() {
        try {
            if (tvModeTitle != null && btnSwitchMode != null) {
                if (isMaskMode) {
                    tvModeTitle.setText("遮罩模式");
                    btnSwitchMode.setText("切换到涂抹模式");
                } else {
                    tvModeTitle.setText("涂抹模式");
                    btnSwitchMode.setText("切换到遮罩模式");
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error updating mode UI: " + e.getMessage(), e);
        }
    }
    
    private void confirmCrop() {
        try {
            Log.d(TAG, "Confirming crop");
            
            if (originalBitmap == null) {
                Toast.makeText(this, "请先拍照", Toast.LENGTH_SHORT).show();
                return;
            }
            
            Bitmap croppedBitmap = null;
            
            if (isMaskMode && maskImageView != null) {
                croppedBitmap = maskImageView.getCroppedBitmap();
            } else if (!isMaskMode && paintImageView != null) {
                croppedBitmap = paintImageView.getCroppedBitmap();
            }
            
            if (croppedBitmap != null) {
                Log.d(TAG, "裁剪成功，尺寸: " + croppedBitmap.getWidth() + "x" + croppedBitmap.getHeight());
                
                Intent resultIntent = new Intent();
                resultIntent.putExtra("cropped_bitmap", croppedBitmap);
                setResult(RESULT_OK, resultIntent);
                finish();
            } else {
                Toast.makeText(this, "请选择识别区域", Toast.LENGTH_SHORT).show();
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error confirming crop: " + e.getMessage(), e);
            Toast.makeText(this, "裁剪失败: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }
    
    private void showErrorAndFinish(String message) {
        Log.e(TAG, "Showing error and finishing: " + message);
        try {
            Toast.makeText(this, message, Toast.LENGTH_LONG).show();
        } catch (Exception e) {
            Log.e(TAG, "Even Toast failed: " + e.getMessage(), e);
        }
        finish();
    }
    
    @Override
    protected void onDestroy() {
        Log.d(TAG, "onDestroy start");
        super.onDestroy();
        
        try {
            // 清理Bitmap内存
            if (originalBitmap != null && !originalBitmap.isRecycled()) {
                originalBitmap.recycle();
                originalBitmap = null;
            }
            
            // 清理临时文件
            if (currentPhotoPath != null) {
                try {
                    File photoFile = new File(currentPhotoPath);
                    if (photoFile.exists()) {
                        boolean deleted = photoFile.delete();
                        Log.d(TAG, "清理临时图片文件: " + deleted);
                    }
                } catch (Exception e) {
                    Log.w(TAG, "清理临时文件失败: " + e.getMessage());
                }
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error in onDestroy: " + e.getMessage(), e);
        }
        
        Log.d(TAG, "onDestroy completed");
    }
}