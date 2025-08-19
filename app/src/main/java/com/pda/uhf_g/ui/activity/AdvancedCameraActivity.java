package com.pda.uhf_g.ui.activity;

import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.RectF;
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
 * 高级拍照Activity
 * 支持遮罩模式和涂抹模式的图像裁剪
 * 修复：使用高分辨率图片而非缩略图
 */
public class AdvancedCameraActivity extends AppCompatActivity {
    
    private static final String TAG = "AdvancedCamera";
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
    
    // 修复：添加高分辨率图片支持
    private String currentPhotoPath;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        try {
            setContentView(R.layout.activity_advanced_camera);
            
            initViews();
            setupListeners();
            
            // 自动启动相机
            startCamera();
        } catch (Exception e) {
            Log.e(TAG, "Activity创建失败: " + e.getMessage(), e);
            Toast.makeText(this, "初始化失败: " + e.getMessage(), Toast.LENGTH_LONG).show();
            finish();
        }
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
    
    // 修复：创建高分辨率图片文件 - 增加错误处理
    private File createImageFile() throws IOException {
        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(new Date());
        String imageFileName = "UHFG_OCR_" + timeStamp + "_";
        
        // 尝试多个存储位置
        File storageDir = getExternalFilesDir(Environment.DIRECTORY_PICTURES);
        if (storageDir == null || !storageDir.exists()) {
            // 如果外部存储不可用，使用内部存储
            storageDir = new File(getFilesDir(), "Pictures");
            Log.w(TAG, "外部存储不可用，使用内部存储: " + storageDir);
        }
        
        if (!storageDir.exists()) {
            boolean created = storageDir.mkdirs();
            Log.d(TAG, "创建存储目录: " + storageDir + ", 成功: " + created);
            if (!created) {
                throw new IOException("无法创建存储目录: " + storageDir);
            }
        }
        
        File image = File.createTempFile(imageFileName, ".jpg", storageDir);
        currentPhotoPath = image.getAbsolutePath();
        Log.d(TAG, "创建图片文件: " + currentPhotoPath);
        
        return image;
    }
    
    // 修复：使用高分辨率拍照 - 增加降级兼容性
    private void startCamera() {
        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        
        if (takePictureIntent.resolveActivity(getPackageManager()) != null) {
            File photoFile = null;
            try {
                photoFile = createImageFile();
            } catch (IOException ex) {
                Log.e(TAG, "创建图片文件失败: " + ex.getMessage());
                Toast.makeText(this, "创建图片文件失败，尝试使用简单模式", Toast.LENGTH_SHORT).show();
                
                // 降级到简单拍照模式
                startSimpleCamera();
                return;
            }
            
            if (photoFile != null) {
                try {
                    Uri photoURI = FileProvider.getUriForFile(this,
                            "com.pda.uhf_g.fileprovider", photoFile);
                    takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI);
                    
                    Log.d(TAG, "启动高分辨率拍照，输出URI: " + photoURI);
                    startActivityForResult(takePictureIntent, REQUEST_IMAGE_CAPTURE);
                } catch (Exception e) {
                    Log.e(TAG, "FileProvider创建URI失败: " + e.getMessage());
                    Toast.makeText(this, "文件访问失败，尝试使用简单模式", Toast.LENGTH_SHORT).show();
                    
                    // 降级到简单拍照模式
                    startSimpleCamera();
                }
            }
        } else {
            Toast.makeText(this, "无法找到相机应用", Toast.LENGTH_SHORT).show();
            finish();
        }
    }
    
    // 降级兼容：简单拍照模式（使用缩略图）
    private void startSimpleCamera() {
        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (takePictureIntent.resolveActivity(getPackageManager()) != null) {
            Log.w(TAG, "使用降级的简单拍照模式");
            startActivityForResult(takePictureIntent, REQUEST_IMAGE_CAPTURE + 1000); // 使用不同的请求码
        }
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        if (resultCode == RESULT_OK) {
            if (requestCode == REQUEST_IMAGE_CAPTURE) {
                // 高分辨率模式：从文件加载图片
                if (currentPhotoPath != null) {
                    loadHighResolutionBitmap();
                } else {
                    Log.e(TAG, "图片路径为空");
                    Toast.makeText(this, "图片加载失败", Toast.LENGTH_SHORT).show();
                    finish();
                }
            } else if (requestCode == REQUEST_IMAGE_CAPTURE + 1000) {
                // 降级模式：从Intent获取缩略图
                Log.w(TAG, "使用降级模式处理拍照结果");
                try {
                    Bundle extras = data.getExtras();
                    originalBitmap = (Bitmap) extras.get("data");
                    
                    if (originalBitmap != null) {
                        Log.w(TAG, "降级模式获得图片: " + originalBitmap.getWidth() + "x" + originalBitmap.getHeight() + 
                                  " (分辨率较低，可能影响OCR效果)");
                        showPhotoEditingView();
                    } else {
                        Log.e(TAG, "降级模式也无法获取图片");
                        Toast.makeText(this, "拍照失败，请重试", Toast.LENGTH_SHORT).show();
                        finish();
                    }
                } catch (Exception e) {
                    Log.e(TAG, "处理降级模式拍照结果失败: " + e.getMessage(), e);
                    Toast.makeText(this, "图片处理失败: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                    finish();
                }
            }
        } else {
            // 用户取消拍照，返回上一页
            Log.d(TAG, "用户取消拍照");
            finish();
        }
    }
    
    // 修复：加载高分辨率图片
    private void loadHighResolutionBitmap() {
        try {
            Log.d(TAG, "开始加载高分辨率图片: " + currentPhotoPath);
            
            // 首先获取图片尺寸信息
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(currentPhotoPath, options);
            
            int imageWidth = options.outWidth;
            int imageHeight = options.outHeight;
            Log.d(TAG, "原始图片尺寸: " + imageWidth + "x" + imageHeight);
            
            // 计算合适的采样率，避免内存溢出，但保持足够清晰度用于OCR
            int maxDimension = 2048; // 最大2048像素，对OCR来说已经足够
            int sampleSize = 1;
            
            if (imageWidth > maxDimension || imageHeight > maxDimension) {
                int widthRatio = Math.round((float) imageWidth / maxDimension);
                int heightRatio = Math.round((float) imageHeight / maxDimension);
                sampleSize = Math.min(widthRatio, heightRatio);
            }
            
            // 加载采样后的高分辨率图片
            options.inJustDecodeBounds = false;
            options.inSampleSize = sampleSize;
            options.inPreferredConfig = Bitmap.Config.ARGB_8888; // 保持高质量
            
            originalBitmap = BitmapFactory.decodeFile(currentPhotoPath, options);
            
            if (originalBitmap != null) {
                Log.d(TAG, "成功加载高分辨率图片: " + originalBitmap.getWidth() + "x" + 
                          originalBitmap.getHeight() + ", 采样率: " + sampleSize);
                showPhotoEditingView();
            } else {
                Log.e(TAG, "图片解码失败");
                Toast.makeText(this, "图片加载失败，请重新拍照", Toast.LENGTH_SHORT).show();
                startCamera(); // 重新拍照
            }
            
        } catch (Exception e) {
            Log.e(TAG, "加载高分辨率图片失败: " + e.getMessage(), e);
            Toast.makeText(this, "图片加载异常: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            startCamera(); // 重新拍照
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
            Log.d(TAG, "裁剪成功，尺寸: " + croppedBitmap.getWidth() + "x" + croppedBitmap.getHeight());
            
            // 返回裁剪后的图片
            Intent resultIntent = new Intent();
            resultIntent.putExtra("cropped_bitmap", croppedBitmap);
            setResult(RESULT_OK, resultIntent);
            finish();
        } else {
            Toast.makeText(this, "请选择识别区域", Toast.LENGTH_SHORT).show();
        }
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        
        // 清理临时文件
        if (currentPhotoPath != null) {
            try {
                File photoFile = new File(currentPhotoPath);
                if (photoFile.exists()) {
                    boolean deleted = photoFile.delete();
                    Log.d(TAG, "清理临时图片文件: " + currentPhotoPath + ", 删除成功: " + deleted);
                }
            } catch (Exception e) {
                Log.w(TAG, "清理临时文件失败: " + e.getMessage());
            }
        }
        
        // 清理Bitmap内存
        if (originalBitmap != null && !originalBitmap.isRecycled()) {
            originalBitmap.recycle();
        }
    }
}