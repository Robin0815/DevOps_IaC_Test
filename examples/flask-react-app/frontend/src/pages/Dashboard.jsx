import React, { useState, useEffect } from 'react';
import {
  Container,
  Grid,
  Paper,
  Typography,
  Box,
  Card,
  CardContent,
  CircularProgress,
  Alert
} from '@mui/material';
import {
  Assignment,
  CheckCircle,
  Schedule,
  TrendingUp
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import api from '../services/api';

const StatCard = ({ title, value, icon, color = 'primary' }) => (
  <Card>
    <CardContent>
      <Box display="flex" alignItems="center" justifyContent="space-between">
        <Box>
          <Typography color="textSecondary" gutterBottom variant="body2">
            {title}
          </Typography>
          <Typography variant="h4" component="div">
            {value}
          </Typography>
        </Box>
        <Box color={`${color}.main`}>
          {icon}
        </Box>
      </Box>
    </CardContent>
  </Card>
);

const Dashboard = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState(null);
  const [recentTasks, setRecentTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      
      // Fetch tasks for stats
      const tasksResponse = await api.get('/api/tasks?per_page=100');
      const tasks = tasksResponse.data.tasks;
      
      // Calculate stats
      const totalTasks = tasks.length;
      const completedTasks = tasks.filter(task => task.completed).length;
      const pendingTasks = totalTasks - completedTasks;
      const highPriorityTasks = tasks.filter(task => task.priority === 'high').length;
      
      setStats({
        total: totalTasks,
        completed: completedTasks,
        pending: pendingTasks,
        highPriority: highPriorityTasks
      });
      
      // Get recent tasks (last 5)
      setRecentTasks(tasks.slice(0, 5));
      
    } catch (err) {
      console.error('Failed to fetch dashboard data:', err);
      setError('Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  if (error) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Alert severity="error">{error}</Alert>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      {/* Welcome Section */}
      <Box mb={4}>
        <Typography variant="h4" component="h1" gutterBottom>
          Welcome back, {user?.username}!
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Here's an overview of your tasks and activity.
        </Typography>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} mb={4}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Tasks"
            value={stats?.total || 0}
            icon={<Assignment fontSize="large" />}
            color="primary"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Completed"
            value={stats?.completed || 0}
            icon={<CheckCircle fontSize="large" />}
            color="success"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Pending"
            value={stats?.pending || 0}
            icon={<Schedule fontSize="large" />}
            color="warning"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="High Priority"
            value={stats?.highPriority || 0}
            icon={<TrendingUp fontSize="large" />}
            color="error"
          />
        </Grid>
      </Grid>

      {/* Recent Tasks */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Recent Tasks
            </Typography>
            {recentTasks.length === 0 ? (
              <Typography color="text.secondary">
                No tasks yet. Create your first task to get started!
              </Typography>
            ) : (
              <Box>
                {recentTasks.map((task) => (
                  <Box
                    key={task.id}
                    sx={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      py: 2,
                      borderBottom: '1px solid',
                      borderColor: 'divider',
                      '&:last-child': {
                        borderBottom: 'none'
                      }
                    }}
                  >
                    <Box>
                      <Typography variant="body1" fontWeight="medium">
                        {task.title}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {task.description || 'No description'}
                      </Typography>
                    </Box>
                    <Box display="flex" alignItems="center" gap={1}>
                      <Typography
                        variant="caption"
                        sx={{
                          px: 1,
                          py: 0.5,
                          borderRadius: 1,
                          bgcolor: task.priority === 'high' ? 'error.light' :
                                   task.priority === 'medium' ? 'warning.light' : 'success.light',
                          color: task.priority === 'high' ? 'error.contrastText' :
                                 task.priority === 'medium' ? 'warning.contrastText' : 'success.contrastText'
                        }}
                      >
                        {task.priority}
                      </Typography>
                      {task.completed && (
                        <CheckCircle color="success" fontSize="small" />
                      )}
                    </Box>
                  </Box>
                ))}
              </Box>
            )}
          </Paper>
        </Grid>

        {/* Quick Actions */}
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Quick Actions
            </Typography>
            <Box display="flex" flexDirection="column" gap={2}>
              <Typography variant="body2" color="text.secondary">
                • Create a new task
              </Typography>
              <Typography variant="body2" color="text.secondary">
                • View all tasks
              </Typography>
              <Typography variant="body2" color="text.secondary">
                • Update your profile
              </Typography>
              <Typography variant="body2" color="text.secondary">
                • Check application metrics
              </Typography>
            </Box>
          </Paper>
        </Grid>
      </Grid>

      {/* System Info */}
      <Box mt={4}>
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            System Information
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2" color="text.secondary">
                <strong>Application:</strong> Flask React CI/CD Demo
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2" color="text.secondary">
                <strong>Version:</strong> 1.0.0
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2" color="text.secondary">
                <strong>User ID:</strong> {user?.id}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2" color="text.secondary">
                <strong>Member Since:</strong> {user?.created_at ? new Date(user.created_at).toLocaleDateString() : 'N/A'}
              </Typography>
            </Grid>
          </Grid>
        </Paper>
      </Box>
    </Container>
  );
};

export default Dashboard;