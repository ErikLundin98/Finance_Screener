import numpy as np
import stats
def mean_variance_market_portfolio(returns: np.ndarray):
    """
    returns: numpy array with historical returns of shape (n_obs, n_assets)
    """
    cov = np.cov(returns)