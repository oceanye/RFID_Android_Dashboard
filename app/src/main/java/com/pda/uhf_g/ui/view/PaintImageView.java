package com.pda.uhf_g.ui.view;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.util.AttributeSet;
import android.view.MotionEvent;

import androidx.appcompat.widget.AppCompatImageView;

import java.util.ArrayList;
import java.util.List;

/**
 * 涂抹模式ImageView
 * 允许用户通过手指涂抹选择文字识别区域
 */
public class PaintImageView extends AppCompatImageView {
    
    private Paint paintBrush;
    private Paint eraseBrush;
    private Canvas drawCanvas;
    private Bitmap canvasBitmap;
    private Path drawPath;
    private List<Path> paths;
    private boolean isEraseMode = false;
    
    private Bitmap imageBitmap;
    
    public PaintImageView(Context context) {
        super(context);
        init();
    }
    
    public PaintImageView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }
    
    public PaintImageView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }
    
    private void init() {
        // 涂抹画笔 - 半透明蓝色
        paintBrush = new Paint();
        paintBrush.setAntiAlias(true);
        paintBrush.setDither(true);
        paintBrush.setColor(0x802196F3);
        paintBrush.setStyle(Paint.Style.STROKE);
        paintBrush.setStrokeJoin(Paint.Join.ROUND);
        paintBrush.setStrokeCap(Paint.Cap.ROUND);
        paintBrush.setStrokeWidth(30f);
        
        // 擦除画笔
        eraseBrush = new Paint();
        eraseBrush.setAntiAlias(true);
        eraseBrush.setDither(true);
        eraseBrush.setColor(0x00000000);
        eraseBrush.setStyle(Paint.Style.STROKE);
        eraseBrush.setStrokeJoin(Paint.Join.ROUND);
        eraseBrush.setStrokeCap(Paint.Cap.ROUND);
        eraseBrush.setStrokeWidth(40f);
        eraseBrush.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
        
        drawPath = new Path();
        paths = new ArrayList<>();
    }
    
    @Override
    public void setImageBitmap(Bitmap bm) {
        super.setImageBitmap(bm);
        this.imageBitmap = bm;
        
        if (bm != null) {
            post(() -> {
                setupDrawingCanvas();
            });
        }
    }
    
    private void setupDrawingCanvas() {
        if (getWidth() <= 0 || getHeight() <= 0) return;
        
        canvasBitmap = Bitmap.createBitmap(getWidth(), getHeight(), Bitmap.Config.ARGB_8888);
        drawCanvas = new Canvas(canvasBitmap);
        
        // 清空之前的路径
        paths.clear();
        invalidate();
    }
    
    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        if (w > 0 && h > 0) {
            setupDrawingCanvas();
        }
    }
    
    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        
        if (canvasBitmap != null) {
            // 绘制涂抹层
            canvas.drawBitmap(canvasBitmap, 0, 0, null);
        }
        
        // 绘制当前路径
        if (!drawPath.isEmpty()) {
            canvas.drawPath(drawPath, isEraseMode ? eraseBrush : paintBrush);
        }
    }
    
    @Override
    public boolean onTouchEvent(MotionEvent event) {
        float touchX = event.getX();
        float touchY = event.getY();
        
        switch (event.getAction()) {
            case MotionEvent.ACTION_DOWN:
                drawPath.moveTo(touchX, touchY);
                break;
                
            case MotionEvent.ACTION_MOVE:
                drawPath.lineTo(touchX, touchY);
                break;
                
            case MotionEvent.ACTION_UP:
                // 将当前路径绘制到画布上
                if (drawCanvas != null) {
                    drawCanvas.drawPath(drawPath, isEraseMode ? eraseBrush : paintBrush);
                }
                paths.add(new Path(drawPath));
                drawPath.reset();
                break;
                
            default:
                return false;
        }
        
        invalidate();
        return true;
    }
    
    /**
     * 切换擦除模式
     */
    public void toggleEraseMode() {
        isEraseMode = !isEraseMode;
    }
    
    /**
     * 清除所有涂抹
     */
    public void clearPaint() {
        if (drawCanvas != null) {
            drawCanvas.drawColor(0, PorterDuff.Mode.CLEAR);
        }
        paths.clear();
        drawPath.reset();
        invalidate();
    }
    
    /**
     * 撤销最后一笔
     */
    public void undoLastStroke() {
        if (!paths.isEmpty()) {
            paths.remove(paths.size() - 1);
            redrawCanvas();
            invalidate();
        }
    }
    
    private void redrawCanvas() {
        if (drawCanvas == null) return;
        
        // 清空画布
        drawCanvas.drawColor(0, PorterDuff.Mode.CLEAR);
        
        // 重新绘制所有路径
        for (Path path : paths) {
            drawCanvas.drawPath(path, paintBrush);
        }
    }
    
    /**
     * 获取裁剪后的图片（只保留涂抹区域）
     */
    public Bitmap getCroppedBitmap() {
        if (imageBitmap == null || canvasBitmap == null) {
            return null;
        }
        
        try {
            // 创建结果图片
            Bitmap resultBitmap = Bitmap.createBitmap(
                imageBitmap.getWidth(), 
                imageBitmap.getHeight(), 
                Bitmap.Config.ARGB_8888
            );
            Canvas resultCanvas = new Canvas(resultBitmap);
            
            // 计算图片在ImageView中的变换矩阵
            float[] imageMatrix = new float[9];
            getImageMatrix().getValues(imageMatrix);
            
            float scaleX = imageMatrix[0];
            float scaleY = imageMatrix[4];
            float transX = imageMatrix[2];
            float transY = imageMatrix[5];
            
            // 创建遮罩
            Bitmap maskBitmap = Bitmap.createBitmap(
                imageBitmap.getWidth(), 
                imageBitmap.getHeight(), 
                Bitmap.Config.ARGB_8888
            );
            Canvas maskCanvas = new Canvas(maskBitmap);
            
            // 将涂抹区域转换到图片坐标系
            Paint maskPaint = new Paint();
            maskPaint.setColor(0xFFFFFFFF);
            maskPaint.setStyle(Paint.Style.STROKE);
            maskPaint.setStrokeWidth(30f / scaleX); // 调整画笔大小
            maskPaint.setStrokeJoin(Paint.Join.ROUND);
            maskPaint.setStrokeCap(Paint.Cap.ROUND);
            
            // 绘制涂抹路径到遮罩
            for (Path path : paths) {
                Path transformedPath = new Path();
                android.graphics.Matrix matrix = new android.graphics.Matrix();
                matrix.setScale(1/scaleX, 1/scaleY);
                matrix.postTranslate(-transX/scaleX, -transY/scaleY);
                path.transform(matrix, transformedPath);
                maskCanvas.drawPath(transformedPath, maskPaint);
            }
            
            // 绘制原图
            resultCanvas.drawBitmap(imageBitmap, 0, 0, null);
            
            // 应用遮罩
            Paint xferPaint = new Paint();
            xferPaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.DST_IN));
            resultCanvas.drawBitmap(maskBitmap, 0, 0, xferPaint);
            
            return resultBitmap;
            
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
    
    /**
     * 检查是否有涂抹内容
     */
    public boolean hasPaintedArea() {
        return !paths.isEmpty();
    }
}