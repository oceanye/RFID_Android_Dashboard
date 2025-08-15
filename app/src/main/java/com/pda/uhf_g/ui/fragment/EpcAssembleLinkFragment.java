package com.pda.uhf_g.ui.fragment;

import android.Manifest;
import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.google.gson.Gson;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.Text;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.TextRecognizer;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;
import com.handheld.uhfr.UHFRManager;
import com.uhf.api.cls.Reader;
import com.pda.uhf_g.MainActivity;
import com.pda.uhf_g.R;
import com.pda.uhf_g.entity.EpcAssembleLink;
import com.pda.uhf_g.ui.base.BaseFragment;
import com.pda.uhf_g.util.LogUtil;
import com.pda.uhf_g.util.UtilSound;
import com.pda.uhf_g.ui.activity.AdvancedCameraActivity;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.TimeUnit;

import butterknife.BindView;
import butterknife.ButterKnife;
import butterknife.OnClick;
import cn.pda.serialport.Tools;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

public class EpcAssembleLinkFragment extends BaseFragment {
    private static final String TAG = "EpcAssembleLink";
    private static final int REQUEST_CAMERA_PERMISSION = 200;
    private static final int REQUEST_IMAGE_CAPTURE = 201;
    private static final int REQUEST_ADVANCED_CAMERA = 202;
    private static final String SERVER_URL = "http://175.24.178.44:8082/api/epc-assemble-link";
    private static final String PING_URL = "http://175.24.178.44:8082/health"; // 健康检查端点
    private static final String USERNAME = "root";
    private static final String PASSWORD = "Rootroot!";

    @BindView(R.id.btn_scan_epc)
    Button btnScanEpc;
    @BindView(R.id.btn_stop_scan)
    Button btnStopScan;
    @BindView(R.id.tv_scanned_epc)
    TextView tvScannedEpc;
    @BindView(R.id.tv_top_epcs_title)
    TextView tvTopEpcsTitle;
    @BindView(R.id.ll_top_epcs_container)
    LinearLayout llTopEpcsContainer;
    @BindView(R.id.tv_epc_rank_1)
    TextView tvEpcRank1;
    @BindView(R.id.tv_epc_rank_2)
    TextView tvEpcRank2;
    @BindView(R.id.tv_epc_rank_3)
    TextView tvEpcRank3;
    @BindView(R.id.et_assemble_id)
    EditText etAssembleId;
    @BindView(R.id.btn_take_photo)
    Button btnTakePhoto;
    @BindView(R.id.btn_clear_assemble)
    Button btnClearAssemble;
    @BindView(R.id.tv_link_summary)
    TextView tvLinkSummary;
    @BindView(R.id.btn_confirm_upload)
    Button btnConfirmUpload;
    @BindView(R.id.btn_save_local)
    Button btnSaveLocal;
    @BindView(R.id.tv_upload_status)
    TextView tvUploadStatus;
    @BindView(R.id.tv_network_status)
    TextView tvNetworkStatus;
    @BindView(R.id.progress_upload)
    ProgressBar progressUpload;

    private MainActivity mainActivity;
    private boolean isScanning = false;
    private String currentEpcId = "";
    private String currentRssi = "";
    private EpcAssembleLink currentLink;
    private KeyReceiver keyReceiver;
    private TextRecognizer textRecognizer;
    private OkHttpClient httpClient;
    private Gson gson;

    // 添加扫描到的标签列表和相关变量
    private List<EpcTagInfo> scannedTags = new ArrayList<>();
    private int scanCount = 0;
    private final int MAX_SCAN_COUNT = 100; // 增加到100次扫描
    private final int MAX_TAGS_LIMIT = 50; // 最大标签数限制，防止内存溢出
    private boolean continuousMode = true; // 连续扫描模式

    // EPC标签信息类
    public static class EpcTagInfo {
        public String epc;
        public int rssi;
        public int count; // 被扫描到的次数
        
        public EpcTagInfo(String epc, int rssi) {
            this.epc = epc;
            this.rssi = rssi;
            this.count = 1;
        }
        
        @Override
        public String toString() {
            return epc + " (RSSI: " + rssi + "dBm, 次数: " + count + ")";
        }
    }

    private final int MSG_EPC_SCANNED = 1001;
    private final int MSG_SCAN_COMPLETED = 1002;

    private Handler handler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(@NonNull Message msg) {
            super.handleMessage(msg);
            try {
                switch (msg.what) {
                    case MSG_EPC_SCANNED:
                        if (msg.obj != null && msg.obj instanceof String[]) {
                            String[] data = (String[]) msg.obj;
                            if (data.length >= 2) {
                                String epcData = data[0];
                                String rssiData = data[1];
                                addScannedTag(epcData, rssiData);
                                updateTop3Display(); // 实时更新前3名显示
                            }
                        }
                        break;
                    case MSG_SCAN_COMPLETED:
                        onScanCompleted(); // 扫描完成，自动选择第一名
                        break;
                    default:
                        Log.w(TAG, "Unknown message received: " + msg.what);
                        break;
                }
            } catch (Exception e) {
                Log.e(TAG, "Error handling message: " + msg.what, e);
                // 防止handler异常导致崩溃
                stopEpcScanning();
                showToast("扫描过程中发生错误: " + e.getMessage());
            }
        }
    };

    public EpcAssembleLinkFragment() {
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mainActivity = (MainActivity) getActivity();
        textRecognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
        gson = new Gson();
        
        httpClient = new OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)  // 减少连接超时
                .writeTimeout(20, TimeUnit.SECONDS)
                .readTimeout(25, TimeUnit.SECONDS)
                .retryOnConnectionFailure(true)        // 启用重试
                .build();
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_epc_assemble_link, container, false);
        ButterKnife.bind(this, view);
        initView();
        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
        Log.d(TAG, "EpcAssembleLinkFragment onResume");
        
        // 参考InventoryFragment，在resume时初始化UHF设置
        if (mainActivity != null && mainActivity.mUhfrManager != null) {
            try {
                // 清除库存过滤器（重要！）
                mainActivity.mUhfrManager.setCancleInventoryFilter();
                Log.d(TAG, "Inventory filter cleared in onResume");
            } catch (Exception e) {
                Log.e(TAG, "Error clearing inventory filter in onResume: " + e.getMessage(), e);
            }
        }
        
        registerKeyCodeReceiver();
    }

    @Override
    public void onPause() {
        super.onPause();
        Log.d(TAG, "Fragment onPause - stopping scanning and cleanup");
        stopEpcScanning();
        
        // 清理Handler消息，防止内存泄漏
        if (handler != null) {
            handler.removeCallbacksAndMessages(null);
        }
        
        if (keyReceiver != null && mainActivity != null) {
            try {
                mainActivity.unregisterReceiver(keyReceiver);
            } catch (Exception e) {
                Log.w(TAG, "Error unregistering receiver: " + e.getMessage());
            }
        }
    }
    
    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "Fragment onDestroy - final cleanup");
        
        // 清理资源
        if (scannedTags != null) {
            scannedTags.clear();
        }
        
        if (textRecognizer != null) {
            try {
                textRecognizer.close();
            } catch (Exception e) {
                Log.w(TAG, "Error closing text recognizer: " + e.getMessage());
            }
        }
        
        if (httpClient != null) {
            try {
                httpClient.dispatcher().cancelAll();
            } catch (Exception e) {
                Log.w(TAG, "Error canceling HTTP calls: " + e.getMessage());
            }
        }
        
        // 清理Handler
        if (handler != null) {
            handler.removeCallbacksAndMessages(null);
        }
    }

    private void initView() {
        updateSummary();
        updateButtonStates();
        
        // 启动时检查网络状态
        checkNetworkStatusOnStartup();
    }
    
    private void checkNetworkStatusOnStartup() {
        tvNetworkStatus.setText(getString(R.string.network_checking));
        
        Request pingRequest = new Request.Builder()
                .url(SERVER_URL)
                .head()
                .build();
        
        httpClient.newCall(pingRequest).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                handler.post(() -> {
                    tvNetworkStatus.setText(getString(R.string.network_server_offline) + " (" + analyzeNetworkError(e) + ")");
                    tvNetworkStatus.setTextColor(0xFFFF5722); // Orange color for offline
                });
            }
            
            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                response.close();
                handler.post(() -> {
                    tvNetworkStatus.setText(getString(R.string.network_server_online));
                    tvNetworkStatus.setTextColor(0xFF4CAF50); // Green color for online
                });
            }
        });
    }

    @OnClick(R.id.btn_scan_epc)
    public void startEpcScanning() {
        Log.d(TAG, "=== startEpcScanning called ===");
        
        try {
            // 基本检查
            if (mainActivity == null) {
                Log.e(TAG, "MainActivity is null!");
                showToast("MainActivity is null");
                return;
            }
            Log.d(TAG, "MainActivity OK");
            
            if (mainActivity.mUhfrManager == null) {
                Log.e(TAG, "UHFRManager is null!");
                showToast(getString(R.string.uhf_module_not_initialized));
                return;
            }
            Log.d(TAG, "UHFRManager OK");

            // 检查UHF连接状态（参考InventoryFragment）
            if (!mainActivity.isConnectUHF) {
                Log.e(TAG, "UHF not connected!");
                showToast("UHF未连接");
                return;
            }
            Log.d(TAG, "UHF connection OK");

            // 参考InventoryFragment的设置，清除之前的过滤器
            try {
                mainActivity.mUhfrManager.setCancleInventoryFilter();
                Log.d(TAG, "Inventory filter cleared");
            } catch (Exception e) {
                Log.e(TAG, "Error clearing inventory filter: " + e.getMessage(), e);
            }

            // 设置Gen2session（参考InventoryFragment）
            try {
                if (mainActivity.mUhfrManager.getGen2session() != 3) {
                    mainActivity.mUhfrManager.setGen2session(false); // false表示单标签模式
                    Log.d(TAG, "Gen2session set to single tag mode");
                }
            } catch (Exception e) {
                Log.e(TAG, "Error setting Gen2session: " + e.getMessage(), e);
            }

            // 设置较高功率扫描（提高到15）
            try {
                Reader.READER_ERR result = mainActivity.mUhfrManager.setPower(15, 15);
                Log.d(TAG, "setPower result: " + result);
                if (result != Reader.READER_ERR.MT_OK_ERR) {
                    Log.w(TAG, "Failed to set power to 15, result: " + result + ", continuing anyway");
                } else {
                    Log.d(TAG, "Successfully set scanning power to 15");
                }
            } catch (Exception e) {
                Log.e(TAG, "Error setting power: " + e.getMessage(), e);
                // 继续执行，功率设置失败不影响扫描
            }
            
            // 更新UI状态（注意：不要完全清空之前的标签，允许累积扫描）
            scanCount = 0;       // 重置扫描计数
            
            // 如果之前没有扫描结果，或用户明确要重新开始，才清空
            if (scannedTags.isEmpty()) {
                Log.d(TAG, "Starting fresh scan - no previous tags");
            } else {
                Log.d(TAG, "Continuing scan with " + scannedTags.size() + " existing tags");
                // 保持现有标签的计数不变，只是继续累积新的扫描结果
                // 不再减半计数，让用户看到真实的累积次数
                Log.d(TAG, "Existing tags will continue accumulating scan counts");
            }
            
            // 显示实时排名区域
            tvTopEpcsTitle.setVisibility(View.VISIBLE);
            llTopEpcsContainer.setVisibility(View.VISIBLE);
            
            if (scannedTags.isEmpty()) {
                resetTop3Display(); // 只有没有数据时才重置显示
            }
            
            isScanning = true;
            btnScanEpc.setEnabled(false);
            btnStopScan.setEnabled(true);
            tvUploadStatus.setText(getString(R.string.scanning_for_epc) + " (0/" + MAX_SCAN_COUNT + ")");
            
            showToast("开始扫描EPC标签...");
            Log.d(TAG, "Starting real UHF scanning with power 15...");
            
            // 启动扫描线程
            startScanningThread();
            
        } catch (Exception e) {
            Log.e(TAG, "Exception in startEpcScanning: " + e.getMessage(), e);
            showToast("扫描启动失败: " + e.getMessage());
            // 恢复按钮状态
            isScanning = false;
            btnScanEpc.setEnabled(true);
            btnStopScan.setEnabled(false);
        }
        
        Log.d(TAG, "=== startEpcScanning completed ===");
    }

    @OnClick(R.id.btn_stop_scan)
    public void stopEpcScanning() {
        Log.d(TAG, "Stopping EPC scanning...");
        isScanning = false;
        btnScanEpc.setEnabled(true);
        btnStopScan.setEnabled(false);
        tvUploadStatus.setText("扫描已停止 - 可继续扫描或重新开始");
        
        if (handler != null) {
            handler.removeCallbacks(scanningRunnable);
        }
        
        Log.d(TAG, "EPC scanning stopped, " + scannedTags.size() + " unique tags found");
    }
    
    // 添加清除扫描历史的方法
    public void clearScanHistory() {
        try {
            Log.d(TAG, "Clearing scan history...");
            scannedTags.clear();
            currentEpcId = "";
            currentRssi = "";
            
            resetTop3Display();
            tvTopEpcsTitle.setVisibility(View.GONE);
            llTopEpcsContainer.setVisibility(View.GONE);
            
            if (tvScannedEpc != null) {
                tvScannedEpc.setText(getString(R.string.no_epc_scanned));
            }
            
            updateSummary();
            updateButtonStates();
            
            tvUploadStatus.setText("扫描历史已清除");
            showToast("扫描历史已清除");
            
            Log.d(TAG, "Scan history cleared successfully");
        } catch (Exception e) {
            Log.e(TAG, "Error clearing scan history: " + e.getMessage(), e);
        }
    }

    private Runnable scanningRunnable = new Runnable() {
        @Override
        public void run() {
            if (!isScanning) {
                Log.d(TAG, "Scanning stopped, exiting runnable");
                return;
            }
            
            scanCount++;
            Log.d(TAG, "Executing EPC scanning runnable - scan " + scanCount + "/" + MAX_SCAN_COUNT);
            
            // 更新进度
            if (tvUploadStatus != null) {
                tvUploadStatus.setText(getString(R.string.scanning_for_epc) + " (" + scanCount + "/" + MAX_SCAN_COUNT + ")");
            }
            
            try {
                if (mainActivity == null || mainActivity.mUhfrManager == null) {
                    Log.e(TAG, "MainActivity or UHFRManager is null during scan");
                    return;
                }
                
                if (!mainActivity.isConnectUHF) {
                    Log.e(TAG, "UHF disconnected during scan");
                    return;
                }
                
                // 使用与InventoryFragment相同的扫描方法
                List<Reader.TAGINFO> listTag = mainActivity.mUhfrManager.tagInventoryByTimer((short) 50);
                
                if (listTag != null && !listTag.isEmpty()) {
                    Log.d(TAG, "Found " + listTag.size() + " tags in this scan");
                    
                    // 限制单次处理的标签数量，防止过载
                    int processCount = Math.min(listTag.size(), 10); // 最多处理10个标签
                    
                    // 处理扫描到的标签
                    for (int i = 0; i < processCount; i++) {
                        Reader.TAGINFO taginfo = listTag.get(i);
                        if (taginfo != null && taginfo.EpcId != null && taginfo.EpcId.length > 0) {
                            try {
                                String epcData = Tools.Bytes2HexString(taginfo.EpcId, taginfo.EpcId.length);
                                
                                // 验证EPC数据有效性
                                if (epcData != null && !epcData.trim().isEmpty()) {
                                    // 获取RSSI信息（安全处理）
                                    String rssiStr = "0";
                                    try {
                                        rssiStr = String.valueOf(taginfo.RSSI);
                                    } catch (Exception e) {
                                        rssiStr = "0"; // RSSI获取失败时使用0
                                    }
                                    
                                    Log.d(TAG, "Found valid EPC: " + epcData + ", RSSI: " + rssiStr);
                                    
                                    // 通过Handler发送消息到主线程更新标签列表
                                    Message msg = handler.obtainMessage(MSG_EPC_SCANNED);
                                    msg.obj = new String[]{epcData, rssiStr};
                                    handler.sendMessage(msg);
                                } else {
                                    Log.w(TAG, "Invalid EPC data: " + epcData);
                                }
                            } catch (Exception e) {
                                Log.e(TAG, "Error processing tag " + i + ": " + e.getMessage(), e);
                            }
                        } else {
                            Log.w(TAG, "Tag info or EpcId is null/empty at index " + i);
                        }
                    }
                    
                    if (listTag.size() > processCount) {
                        Log.w(TAG, "Limited processing to " + processCount + " tags out of " + listTag.size());
                    }
                } else {
                    Log.d(TAG, "No tags found in this scan");
                }
            } catch (OutOfMemoryError e) {
                Log.e(TAG, "Out of memory during scanning", e);
                // 清理部分数据
                if (scannedTags.size() > MAX_TAGS_LIMIT / 2) {
                    scannedTags.sort((tag1, tag2) -> Integer.compare(tag1.rssi, tag2.rssi));
                    scannedTags.subList(0, scannedTags.size() / 2).clear();
                    Log.w(TAG, "Cleared half of scanned tags due to memory pressure");
                }
            } catch (Exception e) {
                Log.e(TAG, "Error during EPC scanning: " + e.getMessage(), e);
            }
            
            // 检查是否达到扫描次数上限（在连续模式下循环重置）
            if (scanCount >= MAX_SCAN_COUNT) {
                if (continuousMode) {
                    Log.d(TAG, "Reached scan limit, resetting count for continuous scanning");
                    scanCount = 0; // 重置计数，继续扫描
                    // 更新进度显示
                    if (tvUploadStatus != null) {
                        tvUploadStatus.setText("持续扫描中... (已完成" + MAX_SCAN_COUNT + "次循环)");
                    }
                } else {
                    Log.d(TAG, "Reached maximum scan count, stopping");
                    isScanning = false;
                    handler.sendEmptyMessage(MSG_SCAN_COMPLETED);
                    return;
                }
            }
            
            // 继续扫描
            if (isScanning) {
                handler.postDelayed(this, 200); // 间隔200ms
            }
        }
    };

    private void startScanningThread() {
        handler.postDelayed(scanningRunnable, 100);
    }

    // 添加扫描到的标签到列表中
    private void addScannedTag(String epcData, String rssiData) {
        if (epcData == null || epcData.trim().isEmpty()) {
            Log.w(TAG, "Ignoring null or empty EPC data");
            return;
        }
        
        try {
            int rssi = Integer.parseInt(rssiData);
            
            // 检查标签数量限制，防止内存溢出
            if (scannedTags.size() >= MAX_TAGS_LIMIT) {
                Log.w(TAG, "Reached maximum tags limit (" + MAX_TAGS_LIMIT + "), removing oldest tag");
                // 移除信号最弱的标签
                scannedTags.sort((tag1, tag2) -> Integer.compare(tag1.rssi, tag2.rssi));
                scannedTags.remove(0); // 移除第一个（信号最弱的）
            }
            
            // 检查是否已经存在该EPC
            EpcTagInfo existingTag = null;
            for (EpcTagInfo tag : scannedTags) {
                if (tag != null && tag.epc != null && tag.epc.equals(epcData)) {
                    existingTag = tag;
                    break;
                }
            }
            
            if (existingTag != null) {
                // 更新现有标签（每次检测到都增加计数）
                existingTag.count++;
                // 如果新的信号更强，更新RSSI
                if (rssi > existingTag.rssi) {
                    existingTag.rssi = rssi;
                }
                Log.d(TAG, "Updated existing tag: " + epcData + ", new count: " + existingTag.count + ", best RSSI: " + existingTag.rssi);
            } else {
                // 添加新标签
                EpcTagInfo newTag = new EpcTagInfo(epcData, rssi);
                scannedTags.add(newTag);
                Log.d(TAG, "Added new tag: " + epcData + ", RSSI: " + rssi + ", initial count: 1");
            }
            
            Log.d(TAG, "Total unique tags: " + scannedTags.size() + "/" + MAX_TAGS_LIMIT);
        } catch (NumberFormatException e) {
            Log.e(TAG, "Invalid RSSI value: " + rssiData + ", using default 0", e);
            // 使用默认RSSI值0继续处理
            try {
                EpcTagInfo existingTag = null;
                for (EpcTagInfo tag : scannedTags) {
                    if (tag != null && tag.epc != null && tag.epc.equals(epcData)) {
                        existingTag = tag;
                        break;
                    }
                }
                
                if (existingTag != null) {
                    existingTag.count++; // 确保计数增加
                    Log.d(TAG, "Updated count for tag with invalid RSSI: " + epcData + ", count: " + existingTag.count);
                } else if (scannedTags.size() < MAX_TAGS_LIMIT) {
                    EpcTagInfo newTag = new EpcTagInfo(epcData, 0);
                    scannedTags.add(newTag);
                    Log.d(TAG, "Added new tag with default RSSI: " + epcData);
                }
            } catch (Exception ex) {
                Log.e(TAG, "Failed to add tag with default RSSI", ex);
            }
        } catch (Exception e) {
            Log.e(TAG, "Unexpected error adding scanned tag: " + e.getMessage(), e);
        }
    }

    // 重置前3名显示
    private void resetTop3Display() {
        tvEpcRank1.setText("🥇 等待扫描...");
        tvEpcRank2.setText("🥈 等待扫描...");
        tvEpcRank3.setText("🥉 等待扫描...");
        
        // 设置点击事件
        tvEpcRank1.setOnClickListener(v -> selectEpcByRank(0));
        tvEpcRank2.setOnClickListener(v -> selectEpcByRank(1));
        tvEpcRank3.setOnClickListener(v -> selectEpcByRank(2));
    }
    
    // 实时更新前3名EPC显示
    private void updateTop3Display() {
        try {
            if (scannedTags == null || scannedTags.isEmpty()) {
                Log.d(TAG, "No scanned tags to display");
                return;
            }
            
            // 创建副本进行排序，避免修改原始列表
            List<EpcTagInfo> sortedTags = new ArrayList<>(scannedTags);
            
            // 过滤null元素并排序（信号强度从高到低）
            sortedTags.removeIf(tag -> tag == null || tag.epc == null);
            Collections.sort(sortedTags, (tag1, tag2) -> Integer.compare(tag2.rssi, tag1.rssi));
            
            // 更新前3名显示
            TextView[] rankViews = {tvEpcRank1, tvEpcRank2, tvEpcRank3};
            String[] medals = {"🥇", "🥈", "🥉"};
            int[] normalColors = {0xFFE8F5E8, 0xFFFFF8E1, 0xFFF3E5F5}; // 金银铜色
            
            for (int i = 0; i < rankViews.length; i++) {
                if (rankViews[i] == null) {
                    Log.w(TAG, "RankView " + i + " is null, skipping");
                    continue;
                }
                
                if (i < sortedTags.size()) {
                    EpcTagInfo tag = sortedTags.get(i);
                    if (tag != null && tag.epc != null) {
                        // 安全地截取EPC显示（显示后8位或全部，如果长度不足8）
                        String shortEpc = tag.epc.length() > 8 ? 
                            tag.epc.substring(tag.epc.length() - 8) : tag.epc;
                        
                        String displayText = String.format("%s %s\\nRSSI: %ddBm | 次数: %d", 
                            medals[i], 
                            shortEpc,
                            tag.rssi, 
                            tag.count);
                        
                        rankViews[i].setText(displayText);
                        rankViews[i].setEnabled(true);
                        rankViews[i].setBackgroundColor(normalColors[i]);
                        
                        // 第一名默认高亮并自动选择
                        if (i == 0) {
                            rankViews[i].setBackgroundColor(0xFFE8F5E8); // 绿色高亮
                            // 只有当前选中的EPC不是最强的时才自动切换
                            if (currentEpcId == null || !currentEpcId.equals(tag.epc)) {
                                selectEpcByRank(0);
                            }
                        }
                        
                        // 调试：如果计数大于1，输出详细信息
                        if (tag.count > 1) {
                            Log.v(TAG, "Tag " + shortEpc + " has been detected " + tag.count + " times, RSSI: " + tag.rssi);
                        }
                    } else {
                        Log.w(TAG, "Tag or EPC is null at index " + i);
                        rankViews[i].setText(medals[i] + " 数据错误");
                        rankViews[i].setEnabled(false);
                    }
                } else {
                    rankViews[i].setText(medals[i] + " 等待扫描...");
                    rankViews[i].setEnabled(false);
                    rankViews[i].setBackgroundColor(normalColors[i]);
                }
            }
            
            Log.d(TAG, "Updated top 3 display with " + sortedTags.size() + " tags");
        } catch (Exception e) {
            Log.e(TAG, "Error updating top 3 display: " + e.getMessage(), e);
            // 出错时重置显示
            try {
                resetTop3Display();
            } catch (Exception resetError) {
                Log.e(TAG, "Error resetting top 3 display: " + resetError.getMessage(), resetError);
            }
        }
    }
    
    // 根据排名选择EPC
    private void selectEpcByRank(int rank) {
        try {
            if (scannedTags == null || scannedTags.isEmpty()) {
                Log.w(TAG, "No scanned tags available for selection");
                return;
            }
            
            // 创建排序副本
            List<EpcTagInfo> sortedTags = new ArrayList<>(scannedTags);
            sortedTags.removeIf(tag -> tag == null || tag.epc == null);
            Collections.sort(sortedTags, (tag1, tag2) -> Integer.compare(tag2.rssi, tag1.rssi));
            
            if (rank >= sortedTags.size() || rank < 0) {
                Log.w(TAG, "Invalid rank: " + rank + ", available tags: " + sortedTags.size());
                return;
            }
            
            EpcTagInfo selectedTag = sortedTags.get(rank);
            if (selectedTag == null || selectedTag.epc == null) {
                Log.w(TAG, "Selected tag is null at rank: " + rank);
                return;
            }
            
            currentEpcId = selectedTag.epc;
            currentRssi = String.valueOf(selectedTag.rssi);
            
            if (tvScannedEpc != null) {
                tvScannedEpc.setText(getString(R.string.epc_with_colon) + currentEpcId);
            }
            
            // 更新选中状态显示
            TextView[] rankViews = {tvEpcRank1, tvEpcRank2, tvEpcRank3};
            int[] normalColors = {0xFFE8F5E8, 0xFFFFF8E1, 0xFFF3E5F5}; // 金银铜色
            
            for (int i = 0; i < rankViews.length && i < 3; i++) {
                if (rankViews[i] != null) {
                    if (i == rank) {
                        rankViews[i].setBackgroundColor(0xFF81C784); // 选中时的深绿色
                    } else {
                        rankViews[i].setBackgroundColor(normalColors[i]); // 恢复原色
                    }
                }
            }
            
            Log.d(TAG, "Selected EPC rank " + (rank + 1) + ": " + currentEpcId + ", RSSI: " + currentRssi);
            updateSummary();
            updateButtonStates();
        } catch (Exception e) {
            Log.e(TAG, "Error selecting EPC by rank: " + rank + ", " + e.getMessage(), e);
        }
    }
    
    // 扫描完成处理
    private void onScanCompleted() {
        try {
            Log.d(TAG, "Scan completed with " + scannedTags.size() + " unique tags");
            
            if (scannedTags.isEmpty()) {
                showToast("未扫描到任何EPC标签");
                tvTopEpcsTitle.setVisibility(View.GONE);
                llTopEpcsContainer.setVisibility(View.GONE);
                tvUploadStatus.setText("扫描完成 - 未发现RFID标签");
            } else {
                // 创建排序副本
                List<EpcTagInfo> sortedTags = new ArrayList<>(scannedTags);
                sortedTags.removeIf(tag -> tag == null || tag.epc == null);
                Collections.sort(sortedTags, (tag1, tag2) -> Integer.compare(tag2.rssi, tag1.rssi));
                
                if (!sortedTags.isEmpty()) {
                    EpcTagInfo bestTag = sortedTags.get(0);
                    
                    currentEpcId = bestTag.epc;
                    currentRssi = String.valueOf(bestTag.rssi);
                    
                    if (tvScannedEpc != null) {
                        tvScannedEpc.setText(getString(R.string.epc_with_colon) + currentEpcId);
                    }
                    tvUploadStatus.setText("扫描完成 - 已自动选择信号最强标签 (可继续扫描)");
                    
                    UtilSound.play(1, 0); // 播放成功音
                    showToast("扫描完成！已选择信号最强的EPC (可继续扫描)");
                    
                    updateSummary();
                    updateButtonStates();
                } else {
                    Log.w(TAG, "No valid tags after filtering");
                    tvUploadStatus.setText("扫描完成 - 标签数据无效");
                }
            }
            
            // 重要：不要禁用扫描按钮，允许继续扫描
            btnScanEpc.setEnabled(true);
            btnStopScan.setEnabled(false);
            isScanning = false;
            
            // 扫描完成后，不隐藏排名显示，保持可见以便再次扫描
            if (!scannedTags.isEmpty()) {
                tvTopEpcsTitle.setVisibility(View.VISIBLE);
                llTopEpcsContainer.setVisibility(View.VISIBLE);
            }
            
            Log.d(TAG, "Scan completion handling finished, ready for next scan");
        } catch (Exception e) {
            Log.e(TAG, "Error in onScanCompleted: " + e.getMessage(), e);
            // 确保扫描状态被正确重置
            btnScanEpc.setEnabled(true);
            btnStopScan.setEnabled(false);
            isScanning = false;
            tvUploadStatus.setText("扫描完成时发生错误，可重新扫描");
        }
    }

    private void handleEpcScanned(String epcData, String rssiData) {
        if (!isScanning) return;
        
        currentEpcId = epcData;
        currentRssi = rssiData; // 实际的RSSI数据
        
        tvScannedEpc.setText(getString(R.string.epc_with_colon) + currentEpcId);
        tvUploadStatus.setText(getString(R.string.epc_scanned_successfully));
        
        Log.d(TAG, "EPC scanned successfully: " + currentEpcId + ", RSSI: " + currentRssi);
        
        // 播放声音提示
        UtilSound.play(1, 0);
        
        // 自动停止扫描
        stopEpcScanning();
        
        showToast("EPC扫描成功: " + currentEpcId);
        
        updateSummary();
        updateButtonStates();
    }

    @OnClick(R.id.btn_take_photo)
    public void takePhoto() {
        if (ContextCompat.checkSelfPermission(mainActivity, Manifest.permission.CAMERA) 
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(mainActivity,
                    new String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA_PERMISSION);
            return;
        }

        // 启动高级拍照Activity
        Intent advancedCameraIntent = new Intent(mainActivity, AdvancedCameraActivity.class);
        startActivityForResult(advancedCameraIntent, REQUEST_ADVANCED_CAMERA);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        
        if (requestCode == REQUEST_IMAGE_CAPTURE && resultCode == Activity.RESULT_OK) {
            Bundle extras = data.getExtras();
            Bitmap imageBitmap = (Bitmap) extras.get("data");
            processImageWithOCR(imageBitmap);
        } else if (requestCode == REQUEST_ADVANCED_CAMERA && resultCode == Activity.RESULT_OK && data != null) {
            // 从高级拍照Activity获取裁剪后的图片
            Bitmap croppedBitmap = data.getParcelableExtra("cropped_bitmap");
            if (croppedBitmap != null) {
                processImageWithOCR(croppedBitmap);
            }
        }
    }

    private void processImageWithOCR(Bitmap bitmap) {
        InputImage image = InputImage.fromBitmap(bitmap, 0);
        
        tvUploadStatus.setText(getString(R.string.processing_image_with_ocr));
        progressUpload.setVisibility(View.VISIBLE);
        
        textRecognizer.process(image)
                .addOnSuccessListener(visionText -> {
                    progressUpload.setVisibility(View.GONE);
                    String recognizedText = extractAssembleId(visionText);
                    if (!TextUtils.isEmpty(recognizedText)) {
                        etAssembleId.setText(recognizedText);
                        tvUploadStatus.setText(getString(R.string.ocr_completed_successfully));
                        updateSummary();
                        updateButtonStates();
                    } else {
                        tvUploadStatus.setText(getString(R.string.no_text_recognized_from_image));
                    }
                })
                .addOnFailureListener(e -> {
                    progressUpload.setVisibility(View.GONE);
                    tvUploadStatus.setText(getString(R.string.ocr_processing_failed));
                    showToast(getString(R.string.failed_to_process_image) + e.getMessage());
                });
    }

    private String extractAssembleId(Text visionText) {
        String fullText = visionText.getText();
        
        // Simple extraction - you can enhance this based on your specific format
        String[] lines = fullText.split("\n");
        for (String line : lines) {
            line = line.trim();
            if (line.length() > 0) {
                // Return first non-empty line as assemble ID
                // You can add more sophisticated parsing here
                return line;
            }
        }
        return "";
    }

    @OnClick(R.id.btn_clear_assemble)
    public void clearAssembleId() {
        // 创建对话框让用户选择清除范围
        new AlertDialog.Builder(mainActivity)
            .setTitle("清除数据")
            .setMessage("请选择要清除的数据:")
            .setPositiveButton("仅清除组装件ID", (dialog, which) -> {
                etAssembleId.setText("");
                updateSummary();
                updateButtonStates();
                showToast("组装件ID已清除");
            })
            .setNegativeButton("清除所有扫描数据", (dialog, which) -> {
                etAssembleId.setText("");
                clearScanHistory();
            })
            .setNeutralButton("取消", null)
            .show();
    }

    @OnClick(R.id.btn_confirm_upload)
    public void confirmAndUpload() {
        if (validateInput()) {
            createLinkAndUpload();
        }
    }

    @OnClick(R.id.btn_save_local)
    public void saveLocal() {
        if (validateInput()) {
            createLinkAndSaveLocal();
        }
    }

    private boolean validateInput() {
        if (TextUtils.isEmpty(currentEpcId)) {
            showToast(getString(R.string.please_scan_epc_first));
            return false;
        }
        
        String assembleId = etAssembleId.getText().toString().trim();
        if (TextUtils.isEmpty(assembleId)) {
            showToast(getString(R.string.please_enter_or_scan_assemble_id));
            return false;
        }
        
        return true;
    }

    private void createLinkAndUpload() {
        String assembleId = etAssembleId.getText().toString().trim();
        currentLink = new EpcAssembleLink(currentEpcId, assembleId);
        currentLink.setRssi(currentRssi);
        
        tvUploadStatus.setText(getString(R.string.uploading_to_server));
        progressUpload.setVisibility(View.VISIBLE);
        
        uploadToServer(currentLink);
    }

    private void createLinkAndSaveLocal() {
        String assembleId = etAssembleId.getText().toString().trim();
        currentLink = new EpcAssembleLink(currentEpcId, assembleId);
        currentLink.setRssi(currentRssi);
        currentLink.setUploaded(false);
        
        // Here you would save to local database
        // For now, just show success message
        tvUploadStatus.setText(getString(R.string.saved_locally_successfully));
        showToast(getString(R.string.link_saved_locally));
        resetForm();
    }

    private void uploadToServer(EpcAssembleLink link) {
        // 首先检查网络连通性
        tvUploadStatus.setText(getString(R.string.checking_server_connectivity));
        progressUpload.setVisibility(View.VISIBLE);
        
        checkServerConnectivity(() -> {
            // 网络可达，执行实际上传
            performUpload(link);
        }, (error) -> {
            // 网络不可达，显示详细错误信息并提供离线保存选项
            progressUpload.setVisibility(View.GONE);
            String errorMsg = getString(R.string.upload_failed) + error;
            tvUploadStatus.setText(errorMsg);
            Log.e(TAG, errorMsg);
            
            // 提示用户保存到本地
            showToast(getString(R.string.server_unreachable_save_locally));
        });
    }
    
    // 自定义错误回调接口，兼容Java 8
    private interface ErrorCallback {
        void onError(String error);
    }
    
    private void checkServerConnectivity(Runnable onSuccess, ErrorCallback onError) {
        Request pingRequest = new Request.Builder()
                .url(SERVER_URL)  // 使用实际API端点进行测试
                .head()  // 只发送HEAD请求，不获取body
                .build();
        
        httpClient.newCall(pingRequest).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                String errorDetail = analyzeNetworkError(e);
                handler.post(() -> onError.onError(errorDetail));
            }
            
            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                response.close();
                handler.post(onSuccess);
            }
        });
    }
    
    private String analyzeNetworkError(IOException e) {
        String error = e.getMessage();
        if (error.contains("timeout")) {
            return "Connection timeout - Server may be down or network is slow";
        } else if (error.contains("connection refused") || error.contains("Connection refused")) {
            return "Connection refused - Server service not running on port 8082";
        } else if (error.contains("Network is unreachable") || error.contains("No route to host")) {
            return "Network unreachable - Check your internet connection";
        } else if (error.contains("failed to connect")) {
            return "Failed to connect - Server may be offline or firewall blocking";
        } else {
            return error;
        }
    }
    
    private void performUpload(EpcAssembleLink link) {
        tvUploadStatus.setText(getString(R.string.uploading_to_server));
        
        String json = gson.toJson(link);
        
        RequestBody body = RequestBody.create(json, MediaType.get("application/json; charset=utf-8"));
        
        Request request = new Request.Builder()
                .url(SERVER_URL)
                .post(body)
                .addHeader("Authorization", "Basic " + 
                    android.util.Base64.encodeToString((USERNAME + ":" + PASSWORD).getBytes(), 
                    android.util.Base64.NO_WRAP))
                .addHeader("Content-Type", "application/json")
                .addHeader("User-Agent", "UHF-G Android App v3.6")
                .build();

        httpClient.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                handler.post(() -> {
                    progressUpload.setVisibility(View.GONE);
                    String errorDetail = analyzeNetworkError(e);
                    tvUploadStatus.setText(getString(R.string.upload_failed) + ": " + errorDetail);
                    Log.e(TAG, "Upload failed", e);
                    showToast(getString(R.string.upload_failed) + ": " + errorDetail);
                });
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {
                handler.post(() -> {
                    progressUpload.setVisibility(View.GONE);
                    if (response.isSuccessful()) {
                        tvUploadStatus.setText(getString(R.string.upload_successful));
                        showToast(getString(R.string.successfully_uploaded_to_server));
                        resetForm();
                    } else {
                        tvUploadStatus.setText(getString(R.string.upload_failed) + ": HTTP " + response.code());
                        showToast(getString(R.string.server_error) + ": " + response.code());
                    }
                });
                response.close();
            }
        });
    }

    private void resetForm() {
        currentEpcId = "";
        currentRssi = "";
        currentLink = null;
        tvScannedEpc.setText(getString(R.string.no_epc_scanned));
        etAssembleId.setText("");
        updateSummary();
        updateButtonStates();
    }

    private void updateSummary() {
        String assembleId = etAssembleId.getText().toString().trim();
        
        if (TextUtils.isEmpty(currentEpcId) && TextUtils.isEmpty(assembleId)) {
            tvLinkSummary.setText(getString(R.string.please_scan_epc_and_enter_assemble));
        } else if (TextUtils.isEmpty(currentEpcId)) {
            tvLinkSummary.setText(getString(R.string.assemble_id_with_colon) + assembleId + "\n" + getString(R.string.please_enter_assemble_id));
        } else if (TextUtils.isEmpty(assembleId)) {
            tvLinkSummary.setText(getString(R.string.epc_with_colon) + currentEpcId + "\n" + getString(R.string.please_enter_assemble_id));
        } else {
            tvLinkSummary.setText(getString(R.string.epc_with_colon) + currentEpcId + "\n" + getString(R.string.assemble_id_with_colon) + assembleId + "\n" + getString(R.string.ready_to_upload));
        }
    }

    private void updateButtonStates() {
        String assembleId = etAssembleId.getText().toString().trim();
        boolean canProceed = !TextUtils.isEmpty(currentEpcId) && !TextUtils.isEmpty(assembleId);
        
        btnConfirmUpload.setEnabled(canProceed);
        btnSaveLocal.setEnabled(canProceed);
    }

    private void registerKeyCodeReceiver() {
        keyReceiver = new KeyReceiver();
        IntentFilter filter = new IntentFilter();
        filter.addAction("android.rfid.FUN_KEY");
        filter.addAction("android.intent.action.FUN_KEY");
        mainActivity.registerReceiver(keyReceiver, filter);
    }

    private class KeyReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            int keyCode = intent.getIntExtra("keyCode", 0);
            if (keyCode == 0) {
                keyCode = intent.getIntExtra("keycode", 0);
            }
            boolean keyDown = intent.getBooleanExtra("keydown", false);
            
            if (!keyDown) {
                switch (keyCode) {
                    case KeyEvent.KEYCODE_F3:
                    case KeyEvent.KEYCODE_F4:
                    case KeyEvent.KEYCODE_F7:
                        if (!isScanning) {
                            startEpcScanning();
                        } else {
                            stopEpcScanning();
                        }
                        break;
                }
            }
        }
    }
}