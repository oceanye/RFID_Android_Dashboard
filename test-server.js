/**
 * 服务器测试脚本
 * 用于验证 EPC-Assemble Link API 服务器配置是否正确
 */

const http = require('http');

// 测试配置
const SERVER_HOST = '175.24.178.44';
const SERVER_PORT = 8082;
const API_ENDPOINT = '/api/epc-assemble-link';
const HEALTH_ENDPOINT = '/health';

// API 认证信息
const USERNAME = 'root';
const PASSWORD = 'Rootroot!';
const AUTH_HEADER = 'Basic ' + Buffer.from(`${USERNAME}:${PASSWORD}`).toString('base64');

// 测试数据
const TEST_DATA = {
    epcId: 'E2801170200002AA57A555BB',
    assembleId: 'ASM-TEST-002',
    rssi: '-45',
    notes: 'Server configuration test - independent database'
};

console.log('🧪 开始测试 EPC-Assemble Link API 服务器配置...');
console.log('🔒 使用独立数据库配置，不影响现有系统\n');

// 测试函数
function makeRequest(options, data = null) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let body = '';
            
            res.on('data', (chunk) => {
                body += chunk;
            });
            
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    headers: res.headers,
                    body: body
                });
            });
        });
        
        req.on('error', (error) => {
            reject(error);
        });
        
        if (data) {
            req.write(JSON.stringify(data));
        }
        
        req.end();
    });
}

// 测试 1: 基本连接测试
async function testBasicConnection() {
    console.log('1️⃣ 测试基本连接...');
    
    try {
        const options = {
            hostname: SERVER_HOST,
            port: SERVER_PORT,
            path: HEALTH_ENDPOINT,
            method: 'GET',
            timeout: 5000
        };
        
        const response = await makeRequest(options);
        
        if (response.statusCode === 200) {
            console.log('   ✅ 服务器连接正常');
            console.log('   📄 响应:', response.body);
        } else {
            console.log(`   ❌ 连接失败，状态码: ${response.statusCode}`);
        }
        
    } catch (error) {
        console.log(`   ❌ 连接错误: ${error.message}`);
        return false;
    }
    
    return true;
}

// 测试 2: 认证测试
async function testAuthentication() {
    console.log('\n2️⃣ 测试认证机制...');
    
    // 测试无认证
    try {
        const options = {
            hostname: SERVER_HOST,
            port: SERVER_PORT,
            path: API_ENDPOINT,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            timeout: 5000
        };
        
        const response = await makeRequest(options, TEST_DATA);
        
        if (response.statusCode === 401) {
            console.log('   ✅ 无认证请求正确被拒绝 (401)');
        } else {
            console.log(`   ⚠️  预期 401，实际收到: ${response.statusCode}`);
        }
        
    } catch (error) {
        console.log(`   ❌ 认证测试错误: ${error.message}`);
    }
    
    // 测试错误认证
    try {
        const options = {
            hostname: SERVER_HOST,
            port: SERVER_PORT,
            path: API_ENDPOINT,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Basic ' + Buffer.from('wrong:credentials').toString('base64')
            },
            timeout: 5000
        };
        
        const response = await makeRequest(options, TEST_DATA);
        
        if (response.statusCode === 401) {
            console.log('   ✅ 错误认证正确被拒绝 (401)');
        } else {
            console.log(`   ⚠️  预期 401，实际收到: ${response.statusCode}`);
        }
        
    } catch (error) {
        console.log(`   ❌ 错误认证测试错误: ${error.message}`);
    }
}

// 测试 3: API功能测试
async function testAPI() {
    console.log('\n3️⃣ 测试 API 功能...');
    
    try {
        const options = {
            hostname: SERVER_HOST,
            port: SERVER_PORT,
            path: API_ENDPOINT,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': AUTH_HEADER
            },
            timeout: 10000
        };
        
        const response = await makeRequest(options, TEST_DATA);
        
        console.log(`   📊 状态码: ${response.statusCode}`);
        console.log(`   📄 响应: ${response.body}`);
        
        if (response.statusCode === 200) {
            console.log('   ✅ API 功能正常');
            return true;
        } else {
            console.log('   ❌ API 功能异常');
            return false;
        }
        
    } catch (error) {
        console.log(`   ❌ API 测试错误: ${error.message}`);
        return false;
    }
}

// 测试 4: 数据验证测试
async function testDataValidation() {
    console.log('\n4️⃣ 测试数据验证...');
    
    // 测试缺少必需字段
    try {
        const options = {
            hostname: SERVER_HOST,
            port: SERVER_PORT,
            path: API_ENDPOINT,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': AUTH_HEADER
            },
            timeout: 5000
        };
        
        const invalidData = { epcId: 'TEST123' }; // 缺少 assembleId
        const response = await makeRequest(options, invalidData);
        
        if (response.statusCode === 400) {
            console.log('   ✅ 数据验证正常 (400 for missing assembleId)');
        } else {
            console.log(`   ⚠️  预期 400，实际收到: ${response.statusCode}`);
            console.log(`   📄 响应: ${response.body}`);
        }
        
    } catch (error) {
        console.log(`   ❌ 数据验证测试错误: ${error.message}`);
    }
}

// 主测试函数
async function runTests() {
    console.log(`🎯 测试目标: ${SERVER_HOST}:${SERVER_PORT}\n`);
    
    const connectionOK = await testBasicConnection();
    
    if (connectionOK) {
        await testAuthentication();
        const apiOK = await testAPI();
        await testDataValidation();
        
        console.log('\n📋 测试总结:');
        if (apiOK) {
            console.log('✅ 服务器配置正确，API 可以正常使用');
            console.log('🎉 Android 应用现在应该能够成功连接到服务器');
        } else {
            console.log('❌ 服务器配置存在问题，需要检查:');
            console.log('   1. MySQL 数据库连接');
            console.log('   2. API 服务代码');
            console.log('   3. 服务器日志');
        }
    } else {
        console.log('\n❌ 服务器无法连接，请检查:');
        console.log('   1. 服务器是否正在运行 (node server-setup.js)');
        console.log('   2. 端口 8082 是否开放');
        console.log('   3. 防火墙设置');
        console.log('   4. 网络连接');
    }
    
    console.log('\n🔧 如果测试失败，请运行服务器并查看日志:');
    console.log('   npm start');
}

// 运行测试
runTests().catch(error => {
    console.error('💥 测试脚本错误:', error);
    process.exit(1);
});