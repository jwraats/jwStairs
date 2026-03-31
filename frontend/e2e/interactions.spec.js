import { test, expect } from '@playwright/test'

test.describe('Animation Controls Interactions', () => {
  test('Brightness slider can be changed', async ({ page }) => {
    await page.goto('/')

    // Verify the brightness slider exists with correct attributes
    const slider = page.locator('input[type="range"]')
    await expect(slider).toBeVisible()
    await expect(slider).toHaveAttribute('min', '1')
    await expect(slider).toHaveAttribute('max', '100')

    // Change brightness value
    await slider.fill('50')
    await expect(page.getByText('50%')).toBeVisible()

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/brightness-changed.png', fullPage: true })
  })

  test('Color order dropdown can be changed', async ({ page }) => {
    await page.goto('/')

    // Verify the color order select exists with all options
    const select = page.locator('select.select-input')
    await expect(select).toBeVisible()

    const options = ['RGB', 'RBG', 'GRB', 'GBR', 'BRG', 'BGR']
    for (const option of options) {
      await expect(select.locator(`option[value="${option}"]`)).toHaveText(option)
    }

    // Change color order selection
    await select.selectOption('GRB')
    await expect(select).toHaveValue('GRB')

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/color-order-changed.png', fullPage: true })
  })

  test('Repeat animation checkbox can be toggled', async ({ page }) => {
    await page.goto('/')

    // Verify the checkbox exists and is unchecked by default
    const checkbox = page.locator('input[type="checkbox"]')
    await expect(checkbox).toBeVisible()
    await expect(checkbox).not.toBeChecked()

    // Toggle checkbox on
    await checkbox.check()
    await expect(checkbox).toBeChecked()

    // Toggle checkbox off
    await checkbox.uncheck()
    await expect(checkbox).not.toBeChecked()

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/repeat-checkbox-toggled.png', fullPage: true })
  })

  test('Turn Off LEDs button is visible with correct styling', async ({ page }) => {
    await page.goto('/')

    // Verify turn off button exists with correct text and class
    const turnOffButton = page.getByText('🔌 Turn Off LEDs')
    await expect(turnOffButton).toBeVisible()
    await expect(turnOffButton).toHaveClass(/btn-danger/)

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/turn-off-button.png', fullPage: true })
  })

  test('Color pickers are present with default values', async ({ page }) => {
    await page.goto('/')

    // Verify primary and secondary color pickers
    const colorPickers = page.locator('input[type="color"]')
    await expect(colorPickers).toHaveCount(2)

    // Verify default color values are displayed
    await expect(page.getByText('#ff0000', { exact: false })).toBeVisible()
    await expect(page.getByText('#000000', { exact: false })).toBeVisible()

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/color-pickers.png', fullPage: true })
  })
})

test.describe('Scenes Create Form Toggle', () => {
  test('Create Scene button shows form and Cancel hides it', async ({ page }) => {
    await page.goto('/scenes')

    // Verify Create Scene button is visible
    const createButton = page.getByText('+ Create Scene')
    await expect(createButton).toBeVisible()

    // Verify the form is not shown initially
    await expect(page.locator('.create-form')).not.toBeVisible()

    // Click Create Scene to show the form
    await createButton.click()
    await expect(page.locator('.create-form')).toBeVisible()
    await expect(page.getByPlaceholder('Scene name...')).toBeVisible()

    // The Create Scene button should be hidden while form is open
    await expect(createButton).not.toBeVisible()

    // Click Cancel to hide the form
    await page.getByText('Cancel').click()
    await expect(page.locator('.create-form')).not.toBeVisible()

    // The Create Scene button should reappear
    await expect(page.getByText('+ Create Scene')).toBeVisible()

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/scenes-form-toggle.png', fullPage: true })
  })

  test('Create form input accepts text and is focusable', async ({ page }) => {
    await page.goto('/scenes')

    // Open the create form
    await page.getByText('+ Create Scene').click()

    // Verify the text input is present with correct placeholder
    const input = page.getByPlaceholder('Scene name...')
    await expect(input).toBeVisible()
    await expect(input).toHaveAttribute('type', 'text')

    // Focus and type into the input
    await input.click()
    await input.fill('My Test Scene')
    await expect(input).toHaveValue('My Test Scene')

    // Verify form action buttons are visible
    await expect(page.getByRole('button', { name: 'Create' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Cancel' })).toBeVisible()

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/scenes-form-input.png', fullPage: true })
  })
})

test.describe('Scene Detail Page Structure', () => {
  test('Scene detail has information and frames sections', async ({ page }) => {
    await page.goto('/scenes/1')

    // Verify the back button
    await expect(page.getByText('← Back')).toBeVisible()

    // The page may show an error or loading state without backend,
    // but the back button and page structure should still render
    await expect(page.locator('.scene-detail-view')).toBeVisible()

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/scene-detail-structure.png', fullPage: true })
  })

  test('Back button navigates to scenes list', async ({ page }) => {
    await page.goto('/scenes/1')

    // Click the back button
    await page.getByText('← Back').click()

    // Should navigate to the scenes page
    await expect(page.getByRole('heading', { name: 'Scenes' })).toBeVisible()
    await expect(page).toHaveURL(/\/scenes$/)

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/scene-detail-back-nav.png', fullPage: true })
  })
})

test.describe('Navigation Active State', () => {
  test('Animations link is active on home page', async ({ page }) => {
    await page.goto('/')

    // Verify the Animations nav link has the active class
    const animationsLink = page.locator('nav a[href="/"]')
    await expect(animationsLink).toHaveClass(/router-link-active/)

    // Verify the Scenes nav link does not have the active class
    const scenesLink = page.locator('nav a[href="/scenes"]')
    await expect(scenesLink).not.toHaveClass(/router-link-active/)

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/nav-active-animations.png', fullPage: true })
  })

  test('Scenes link is active on scenes page', async ({ page }) => {
    await page.goto('/scenes')

    // Verify the Scenes nav link has the active class
    const scenesLink = page.locator('nav a[href="/scenes"]')
    await expect(scenesLink).toHaveClass(/router-link-active/)

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/nav-active-scenes.png', fullPage: true })
  })

  test('Active state updates after navigation', async ({ page }) => {
    await page.goto('/')

    // Initially Animations is active
    await expect(page.locator('nav a[href="/"]')).toHaveClass(/router-link-active/)

    // Navigate to Scenes
    await page.click('nav a[href="/scenes"]')
    await expect(page.locator('nav a[href="/scenes"]')).toHaveClass(/router-link-active/)

    // Navigate back to Animations
    await page.click('nav a[href="/"]')
    await expect(page.locator('nav a[href="/"]')).toHaveClass(/router-link-active/)

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/nav-active-toggle.png', fullPage: true })
  })
})

test.describe('Responsive Elements and Attributes', () => {
  test('Header contains logo and app title', async ({ page }) => {
    await page.goto('/')

    // Verify the logo icon
    await expect(page.getByText('💡')).toBeVisible()

    // Verify the app title
    await expect(page.getByRole('heading', { name: 'JW Stairs' })).toBeVisible()

    // Verify the header element exists
    await expect(page.locator('header.app-header')).toBeVisible()

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/header-elements.png', fullPage: true })
  })

  test('Navigation links have correct href attributes', async ({ page }) => {
    await page.goto('/')

    // Verify nav links exist with correct hrefs
    const animationsLink = page.locator('nav a[href="/"]')
    await expect(animationsLink).toBeVisible()
    await expect(animationsLink).toHaveText('Animations')

    const scenesLink = page.locator('nav a[href="/scenes"]')
    await expect(scenesLink).toBeVisible()
    await expect(scenesLink).toHaveText('Scenes')

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/nav-links.png', fullPage: true })
  })

  test('Animation controls panel has all control groups', async ({ page }) => {
    await page.goto('/')

    // Verify all control labels are present
    await expect(page.getByText('Brightness')).toBeVisible()
    await expect(page.getByText('Primary Color')).toBeVisible()
    await expect(page.getByText('Secondary Color (Theatre Chase)')).toBeVisible()
    await expect(page.getByText('Color Order')).toBeVisible()
    await expect(page.getByText('Repeat Animation')).toBeVisible()

    // Verify the controls panel section exists
    await expect(page.locator('.controls-panel')).toBeVisible()

    // Verify the shows panel section exists
    await expect(page.locator('.shows-panel')).toBeVisible()
    await expect(page.getByText('Available Shows')).toBeVisible()

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/all-control-groups.png', fullPage: true })
  })

  test('Main content area renders correctly', async ({ page }) => {
    await page.goto('/')

    // Verify the main content wrapper exists
    await expect(page.locator('main.main-content')).toBeVisible()

    // Verify the animations view container exists
    await expect(page.locator('.animations-view')).toBeVisible()

    // Take screenshot
    await page.screenshot({ path: 'e2e/screenshots/main-content.png', fullPage: true })
  })
})
