package com.pda.uhf_g.entity;

import android.os.Build;
import java.io.Serializable;
import java.util.Date;

/**
 * EPC记录实体类 v3.6.4
 * 支持设备追踪和状态管理的增强版本
 */
public class EpcRecord implements Serializable {
    private Long id;
    private String epcId;           // RFID标签ID
    private String deviceId;        // 上传设备号(PDA/PC基站等)
    private String statusNote;      // 备注信息(完成扫描录入/进出场判定等)
    private String assembleId;      // 组装件ID(可选，兼容旧版本)
    private Date createTime;        // 创建时间
    private String rssi;            // 信号强度
    private String deviceType;      // 设备类型(PDA/PC/STATION/MOBILE/OTHER)
    private String location;        // 位置信息(可选)
    private String appVersion;      // 应用版本
    
    public EpcRecord() {
        this.createTime = new Date();
        this.appVersion = "v3.6.4";
        this.deviceId = getDeviceIdentifier();
        this.deviceType = detectDeviceType();
    }
    
    public EpcRecord(String epcId, String statusNote) {
        this();
        this.epcId = epcId;
        this.statusNote = statusNote;
    }
    
    public EpcRecord(String epcId, String assembleId, String statusNote) {
        this();
        this.epcId = epcId;
        this.assembleId = assembleId;
        this.statusNote = statusNote;
    }
    
    /**
     * 获取设备标识符
     */
    private String getDeviceIdentifier() {
        try {
            // 尝试获取设备唯一标识
            String deviceModel = Build.MODEL;
            String deviceManufacturer = Build.MANUFACTURER;
            String deviceSerial = Build.SERIAL;
            
            // 创建设备ID组合
            if (deviceSerial != null && !deviceSerial.equals("unknown")) {
                return deviceManufacturer + "_" + deviceModel + "_" + deviceSerial.substring(0, Math.min(8, deviceSerial.length()));
            } else {
                return deviceManufacturer + "_" + deviceModel + "_" + Build.ID.substring(0, Math.min(8, Build.ID.length()));
            }
        } catch (Exception e) {
            return "ANDROID_DEVICE_" + System.currentTimeMillis() % 100000;
        }
    }
    
    /**
     * 检测设备类型
     */
    private String detectDeviceType() {
        String model = Build.MODEL.toLowerCase();
        String manufacturer = Build.MANUFACTURER.toLowerCase();
        
        // 根据设备型号和制造商判断设备类型
        if (model.contains("pda") || manufacturer.contains("handheld") || 
            model.contains("scanner") || manufacturer.contains("chainway") ||
            manufacturer.contains("urovo") || manufacturer.contains("newland")) {
            return "PDA";
        } else if (model.contains("pc") || model.contains("desktop")) {
            return "PC";
        } else if (model.contains("station") || model.contains("base")) {
            return "STATION";
        } else {
            // 默认移动设备
            return "MOBILE";
        }
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getEpcId() {
        return epcId;
    }
    
    public void setEpcId(String epcId) {
        this.epcId = epcId;
    }
    
    public String getDeviceId() {
        return deviceId;
    }
    
    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }
    
    public String getStatusNote() {
        return statusNote;
    }
    
    public void setStatusNote(String statusNote) {
        this.statusNote = statusNote;
    }
    
    public String getAssembleId() {
        return assembleId;
    }
    
    public void setAssembleId(String assembleId) {
        this.assembleId = assembleId;
    }
    
    public Date getCreateTime() {
        return createTime;
    }
    
    public void setCreateTime(Date createTime) {
        this.createTime = createTime;
    }
    
    public String getRssi() {
        return rssi;
    }
    
    public void setRssi(String rssi) {
        this.rssi = rssi;
    }
    
    public String getDeviceType() {
        return deviceType;
    }
    
    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }
    
    public String getLocation() {
        return location;
    }
    
    public void setLocation(String location) {
        this.location = location;
    }
    
    public String getAppVersion() {
        return appVersion;
    }
    
    public void setAppVersion(String appVersion) {
        this.appVersion = appVersion;
    }
    
    @Override
    public String toString() {
        return "EpcRecord{" +
                "id=" + id +
                ", epcId='" + epcId + '\'' +
                ", deviceId='" + deviceId + '\'' +
                ", statusNote='" + statusNote + '\'' +
                ", assembleId='" + assembleId + '\'' +
                ", createTime=" + createTime +
                ", rssi='" + rssi + '\'' +
                ", deviceType='" + deviceType + '\'' +
                ", location='" + location + '\'' +
                ", appVersion='" + appVersion + '\'' +
                '}';
    }
}