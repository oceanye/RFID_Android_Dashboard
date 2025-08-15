package com.pda.uhf_g.ui.view;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.view.MotionEvent;

import androidx.appcompat.widget.AppCompatImageView;

/**
 * 遮罩模式ImageView
 * 显示中央矩形识别区域，允许用户调整大小和位置
 */
public class MaskImageView extends AppCompatImageView {
    
    private Paint maskPaint;
    private Paint borderPaint;
    private Paint handlePaint;
    
    private RectF recognitionRect;
    private float handleSize = 30f;
    private boolean isDragging = false;
    private boolean isResizing = false;
    private int resizeHandle = -1; // 0=左上, 1=右上, 2=右下, 3=左下
    private float lastTouchX, lastTouchY;
    
    private Bitmap imageBitmap;
    
    public MaskImageView(Context context) {
        super(context);
        init();
    }
    
    public MaskImageView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }
    
    public MaskImageView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }
    
    private void init() {
        // 遮罩画笔 - 半透明黑色
        maskPaint = new Paint();
        maskPaint.setColor(0x80000000);
        maskPaint.setStyle(Paint.Style.FILL);
        
        // 边框画笔 - 白色边框
        borderPaint = new Paint();
        borderPaint.setColor(0xFFFFFFFF);
        borderPaint.setStyle(Paint.Style.STROKE);
        borderPaint.setStrokeWidth(3f);
        
        // 拖拽点画笔 - 蓝色圆点
        handlePaint = new Paint();
        handlePaint.setColor(0xFF2196F3);
        handlePaint.setStyle(Paint.Style.FILL);
        handlePaint.setAntiAlias(true);
    }
    
    @Override
    public void setImageBitmap(Bitmap bm) {
        super.setImageBitmap(bm);
        this.imageBitmap = bm;
        
        if (bm != null && recognitionRect == null) {
            // 初始化识别区域为图片中央的矩形
            post(() -> {
                int width = getWidth();
                int height = getHeight();
                float rectWidth = width * 0.6f;
                float rectHeight = height * 0.3f;
                float left = (width - rectWidth) / 2;
                float top = (height - rectHeight) / 2;
                
                recognitionRect = new RectF(left, top, left + rectWidth, top + rectHeight);
                invalidate();
            });
        }
    }
    
    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        
        if (recognitionRect == null) return;
        
        // 绘制遮罩（除了识别区域）
        Path maskPath = new Path();
        maskPath.addRect(0, 0, getWidth(), getHeight(), Path.Direction.CW);
        maskPath.addRect(recognitionRect, Path.Direction.CCW);
        canvas.drawPath(maskPath, maskPaint);
        
        // 绘制识别区域边框
        canvas.drawRect(recognitionRect, borderPaint);
        
        // 绘制拖拽点
        drawResizeHandles(canvas);
    }
    
    private void drawResizeHandles(Canvas canvas) {
        float radius = handleSize / 2;
        
        // 四个角的拖拽点
        canvas.drawCircle(recognitionRect.left, recognitionRect.top, radius, handlePaint);
        canvas.drawCircle(recognitionRect.right, recognitionRect.top, radius, handlePaint);
        canvas.drawCircle(recognitionRect.right, recognitionRect.bottom, radius, handlePaint);
        canvas.drawCircle(recognitionRect.left, recognitionRect.bottom, radius, handlePaint);
    }
    
    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (recognitionRect == null) return false;
        
        float x = event.getX();
        float y = event.getY();
        
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                lastTouchX = x;
                lastTouchY = y;
                
                // 检查是否点击了拖拽点
                resizeHandle = getResizeHandle(x, y);
                if (resizeHandle >= 0) {
                    isResizing = true;
                    return true;
                }
                
                // 检查是否点击了识别区域内部
                if (recognitionRect.contains(x, y)) {
                    isDragging = true;
                    return true;
                }
                break;
                
            case MotionEvent.ACTION_MOVE:
                float deltaX = x - lastTouchX;
                float deltaY = y - lastTouchY;
                
                if (isResizing && resizeHandle >= 0) {
                    resizeRectangle(resizeHandle, x, y);
                    invalidate();
                } else if (isDragging) {
                    // 移动识别区域
                    recognitionRect.offset(deltaX, deltaY);
                    
                    // 确保不超出边界
                    constrainRectangle();
                    invalidate();
                }
                
                lastTouchX = x;
                lastTouchY = y;
                break;
                
            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                isDragging = false;
                isResizing = false;
                resizeHandle = -1;
                break;
        }
        
        return true;
    }
    
    private int getResizeHandle(float x, float y) {
        float threshold = handleSize;
        
        // 检查四个角
        if (Math.abs(x - recognitionRect.left) < threshold && Math.abs(y - recognitionRect.top) < threshold) {
            return 0; // 左上
        }
        if (Math.abs(x - recognitionRect.right) < threshold && Math.abs(y - recognitionRect.top) < threshold) {
            return 1; // 右上
        }
        if (Math.abs(x - recognitionRect.right) < threshold && Math.abs(y - recognitionRect.bottom) < threshold) {
            return 2; // 右下
        }
        if (Math.abs(x - recognitionRect.left) < threshold && Math.abs(y - recognitionRect.bottom) < threshold) {
            return 3; // 左下
        }
        
        return -1;
    }
    
    private void resizeRectangle(int handle, float x, float y) {
        switch (handle) {
            case 0: // 左上
                recognitionRect.left = Math.min(x, recognitionRect.right - 100);
                recognitionRect.top = Math.min(y, recognitionRect.bottom - 50);
                break;
            case 1: // 右上
                recognitionRect.right = Math.max(x, recognitionRect.left + 100);
                recognitionRect.top = Math.min(y, recognitionRect.bottom - 50);
                break;
            case 2: // 右下
                recognitionRect.right = Math.max(x, recognitionRect.left + 100);
                recognitionRect.bottom = Math.max(y, recognitionRect.top + 50);
                break;
            case 3: // 左下
                recognitionRect.left = Math.min(x, recognitionRect.right - 100);
                recognitionRect.bottom = Math.max(y, recognitionRect.top + 50);
                break;
        }
        
        constrainRectangle();
    }
    
    private void constrainRectangle() {
        // 确保识别区域在视图边界内
        if (recognitionRect.left < 0) {
            recognitionRect.offset(-recognitionRect.left, 0);
        }
        if (recognitionRect.top < 0) {
            recognitionRect.offset(0, -recognitionRect.top);
        }
        if (recognitionRect.right > getWidth()) {
            recognitionRect.offset(getWidth() - recognitionRect.right, 0);
        }
        if (recognitionRect.bottom > getHeight()) {
            recognitionRect.offset(0, getHeight() - recognitionRect.bottom);
        }
    }
    
    /**
     * 获取裁剪后的图片
     */
    public Bitmap getCroppedBitmap() {
        if (imageBitmap == null || recognitionRect == null) {
            return null;
        }
        
        try {
            // 计算图片在ImageView中的实际位置和缩放比例
            float[] imageMatrix = new float[9];
            getImageMatrix().getValues(imageMatrix);
            
            float scaleX = imageMatrix[0];
            float scaleY = imageMatrix[4];
            float transX = imageMatrix[2];
            float transY = imageMatrix[5];
            
            // 将屏幕坐标转换为图片坐标
            float cropX = (recognitionRect.left - transX) / scaleX;
            float cropY = (recognitionRect.top - transY) / scaleY;
            float cropWidth = recognitionRect.width() / scaleX;
            float cropHeight = recognitionRect.height() / scaleY;
            
            // 确保裁剪区域在图片范围内
            cropX = Math.max(0, Math.min(cropX, imageBitmap.getWidth()));
            cropY = Math.max(0, Math.min(cropY, imageBitmap.getHeight()));
            cropWidth = Math.min(cropWidth, imageBitmap.getWidth() - cropX);
            cropHeight = Math.min(cropHeight, imageBitmap.getHeight() - cropY);
            
            if (cropWidth > 0 && cropHeight > 0) {
                return Bitmap.createBitmap(imageBitmap, 
                    (int) cropX, (int) cropY, 
                    (int) cropWidth, (int) cropHeight);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        return null;
    }
}