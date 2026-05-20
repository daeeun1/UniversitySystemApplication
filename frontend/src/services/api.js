import axios from 'axios';

const BACKEND = process.env.REACT_APP_BACKEND_URL || 'http://localhost:18080';
const LLM_GW  = process.env.REACT_APP_LLM_GATEWAY_URL || 'http://localhost:18001';

const api = axios.create({ baseURL: BACKEND });
const llm = axios.create({ baseURL: LLM_GW });

api.interceptors.request.use(cfg => {
  const token = localStorage.getItem('token');
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});

export const authApi = {
  login: (userNumber, password) =>
    api.post('/api/auth/login', { userNumber, password }),
};

export const chatApi = {
  send: (message, token, history = []) =>
    llm.post('/chat', { message, token, conversation_history: history }),
};

export const academicApi = {
  getGrades:   (semester) => api.get('/api/academic/grades', { params: { semester } }),
  getCourses:  (semester, department) =>
    api.get('/api/academic/courses', { params: { semester, department } }),
  enroll:      (courseId) => api.post('/api/academic/courses/enroll', { course_id: courseId }),
  drop:        (courseId) => api.delete('/api/academic/courses/enroll', { params: { course_id: courseId } }),
  graduation:  () => api.get('/api/academic/graduation'),
};

export const studentApi = {
  getInfo:          () => api.get('/api/student/info'),
  applyLeave:       (body) => api.post('/api/student/leave', body),
  applyReinstate:   (semester) => api.post('/api/student/reinstatement', { semester }),
  getLeaveStatus:   () => api.get('/api/student/leave/status'),
};

export const lectureApi = {
  getMyLectures: (semester) => api.get('/api/lecture/my', { params: { semester } }),
  inputGrade:    (body) => api.post('/api/lecture/grades', body),
  getStudents:   (courseId) => api.get('/api/lecture/students', { params: { course_id: courseId } }),
  uploadSyllabus:(body) => api.post('/api/lecture/syllabus', body),
  getAttendance: (courseId) => api.get('/api/lecture/attendance', { params: { course_id: courseId } }),
};

export const adminApi = {
  createUser:    (body) => api.post('/api/admin/users', body),
  assignFunc:    (body) => api.post('/api/admin/rbac/assign', body),
  revokeFunc:    (roleId, funcId) =>
    api.delete('/api/admin/rbac/revoke', { params: { role_id: roleId, function_id: funcId } }),
  setSemester:   (body) => api.post('/api/admin/semester', body),
  getLogs:       (limit) => api.get('/api/admin/logs', { params: { limit } }),
};
