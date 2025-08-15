package com.pda.uhf_g.entity;

import java.io.Serializable;
import java.util.Date;

public class EpcAssembleLink implements Serializable {
    private Long id;
    private String epcId;
    private String assembleId;
    private Date createTime;
    private String rssi;
    private boolean uploaded;
    private String notes;
    
    public EpcAssembleLink() {
        this.createTime = new Date();
        this.uploaded = false;
    }
    
    public EpcAssembleLink(String epcId, String assembleId) {
        this();
        this.epcId = epcId;
        this.assembleId = assembleId;
    }
    
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
    
    public boolean isUploaded() {
        return uploaded;
    }
    
    public void setUploaded(boolean uploaded) {
        this.uploaded = uploaded;
    }
    
    public String getNotes() {
        return notes;
    }
    
    public void setNotes(String notes) {
        this.notes = notes;
    }
    
    @Override
    public String toString() {
        return "EpcAssembleLink{" +
                "id=" + id +
                ", epcId='" + epcId + '\'' +
                ", assembleId='" + assembleId + '\'' +
                ", createTime=" + createTime +
                ", rssi='" + rssi + '\'' +
                ", uploaded=" + uploaded +
                ", notes='" + notes + '\'' +
                '}';
    }
}